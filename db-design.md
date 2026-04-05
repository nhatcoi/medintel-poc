# Thiết kế CSDL MedIntel (local-first, đồng bộ server tùy chọn)

**Nguyên tắc:** Ứng dụng ưu tiên dữ liệu trên thiết bị. Server lưu bản sao để backup / đa thiết bị / (sau này) cộng tác. **Không** dùng IAM cổ điển (mật khẩu, session đăng nhập, OTP xác thực tài khoản) trong giai đoạn này.

- **`profile_id`:** UUID do **client tạo** lần đầu, lưu local, gửi khi sync — server không “đăng ký” bằng email/mật khẩu.
- Mọi FK trước đây gắn `user_id` nay thống nhất là **`profile_id`** (một dòng trong `profiles` = một người dùng app: bệnh nhân hoặc người chăm sóc).
- Bảo mật API sync (token thiết bị, chữ ký, v.v.) là **tầng ứng dụng**, không mô tả chi tiết trong file bảng này — có thể bổ sung khi triển khai.

---

## 1. Định danh & đồng bộ (thay thế Identity & Access Management)

### Bảng `profiles`

`profile_id`: UUID [PK] — tạo trên client, idempotent khi upsert sync

`full_name`: VARCHAR(255) [NN]

`date_of_birth`: DATE

`emergency_contact`: VARCHAR(20)

`role`: profile_role [NN] — ví dụ: patient | caregiver (enum ứng dụng định nghĩa)

`email`: VARCHAR(255) — tùy chọn, **không** bắt buộc unique ban đầu

`phone_number`: VARCHAR(20) — tùy chọn

`created_at`: TIMESTAMP

`updated_at`: TIMESTAMP

`last_server_sync_at`: TIMESTAMP — lần đồng bộ thành công gần nhất (phía server; tùy chọn)

**Đã lược bỏ so với thiết kế cũ:** `password_hash`, `google_id`, `account_status`, `last_login`, ràng buộc UQ bắt buộc trên email/SĐT.

### Bảng `devices` (tùy chọn — đa thiết bị / token sync)

`device_id`: UUID [PK]

`profile_id`: UUID [FK → profiles, NN]

`device_label`: VARCHAR(100) — tên máy / model gợi nhớ

`platform`: VARCHAR(50) — ios | android | …

`sync_credential_hint`: VARCHAR(255) — tham chiếu opaque (hash token), **không** lưu token thô nếu tránh được

`created_at`: TIMESTAMP

`last_seen_at`: TIMESTAMP

### Bảng `audit_logs`

`log_id`: UUID [PK]

`actor_profile_id`: UUID [FK → profiles] — nullable nếu ghi nhận hệ thống/sync

`action_type`: VARCHAR(100) [NN]

`table_name`: VARCHAR(100)

`record_id`: UUID

`old_value`: JSONB

`new_value`: JSONB

`ip_address`: INET — tùy chọn

`user_agent`: TEXT — tùy chọn

`created_at`: TIMESTAMP

**Đã lược bỏ:** bảng `sessions`, bảng `verification_codes`.

---

## 2. Tham chiếu dược (không còn catalog DAV)

**Script gỡ DB (nếu còn bảng cũ):** `server-med/scripts/drop_dav_national_drug_catalog.sql` — xóa nếu tồn tại: `national_drugs`, `drug_basic_info`, `drug_registration_info`, `pharmaceutical_companies`, `countries`, `drug_groups`, `dosage_forms`, `quality_standards`, và cột `medications.national_drug_id`. ORM vẫn định nghĩa `countries` / `drug_groups` / `pharmaceutical_companies`; chạy lại app (`create_all`) sẽ tạo lại các bảng đó rỗng nếu cần.

### Bảng `pharmaceutical_companies`

`company_id`: UUID [PK]

`company_name`: VARCHAR(500) [NN]

`address`: TEXT

`country_id`: UUID [FK]

`company_type`: company_type

`phone`: VARCHAR(50)

`email`: VARCHAR(255)

`website`: VARCHAR(255)

`is_active`: BOOLEAN

`created_at`: TIMESTAMP

`updated_at`: TIMESTAMP

### Bảng `countries`

`country_id`: UUID [PK]

`country_name`: VARCHAR(100) [UQ, NN]

`country_code`: VARCHAR(10)

`created_at`: TIMESTAMP

### Bảng `drug_groups`

`group_id`: SERIAL [PK]

`group_code`: VARCHAR(20)

`group_name`: VARCHAR(255) [NN]

`parent_group_id`: INTEGER [FK]

`description`: TEXT

`created_at`: TIMESTAMP

---

## 3. Medical Records & Treatment

### Bảng `medical_records`

`record_id`: UUID [PK]

`profile_id`: UUID [FK → profiles]

`disease_name`: VARCHAR(255) [NN]

`category_id`: UUID [FK]

`treatment_start_date`: DATE [NN]

`treatment_status`: treatment_status

`treatment_type`: treatment_type

`notes`: TEXT

`created_at`: TIMESTAMP

`updated_at`: TIMESTAMP

### Bảng `disease_categories`

`category_id`: UUID [PK]

`category_name`: VARCHAR(255) [NN]

`description`: TEXT

`created_at`: TIMESTAMP

### Bảng `treatment_periods`

`period_id`: UUID [PK]

`record_id`: UUID [FK]

`period_name`: VARCHAR(255) [NN]

`start_date`: DATE [NN]

`end_date`: DATE

`status`: schedule_status

`notes`: TEXT

`created_at`: TIMESTAMP

`updated_at`: TIMESTAMP

---

## 4. Medication Management

### Bảng `medications`

`medication_id`: UUID [PK]

`period_id`: UUID [FK]

`medication_name`: VARCHAR(255) [NN]

`active_ingredient`: TEXT

`strength`: VARCHAR(100)

`dosage_form`: VARCHAR(100)

`dosage`: VARCHAR(100)

`frequency`: VARCHAR(100)

`route`: VARCHAR(100)

`duration_days`: INTEGER

`start_date`: DATE [NN]

`end_date`: DATE

`instructions`: TEXT

`side_effects`: TEXT

`contraindications`: TEXT

`interactions`: TEXT

`storage_instructions`: TEXT

`prescribing_doctor`: VARCHAR(255)

`prescription_number`: VARCHAR(100)

`prescription_date`: DATE

`total_quantity`: DECIMAL(10,2)

`quantity_unit`: VARCHAR(50)

`remaining_quantity`: DECIMAL(10,2)

`notes`: TEXT

`status`: medication_status

`created_at`: TIMESTAMP

`updated_at`: TIMESTAMP

### Bảng `medication_schedules`

`schedule_id`: UUID [PK]

`medication_id`: UUID [FK]

`scheduled_time`: TIME [NN]

`repeat_pattern`: VARCHAR(50)

`repeat_days`: VARCHAR(50)

`start_date`: DATE

`end_date`: DATE

`reminder_enabled`: BOOLEAN

`reminder_time_before`: INTEGER

`reminder_sound`: VARCHAR(100)

`status`: schedule_status

`created_at`: TIMESTAMP

`updated_at`: TIMESTAMP

### Bảng `medication_logs`

`log_id`: UUID [PK]

`schedule_id`: UUID [FK, NN]

`profile_id`: UUID [FK → profiles, NN] — chủ thể bệnh nhân (thường trùng chủ đơn)

`scheduled_datetime`: TIMESTAMP [NN]

`actual_datetime`: TIMESTAMP

`status`: log_status

`notes`: TEXT

`logged_by_profile_id`: UUID [FK → profiles] — ai ghi (bệnh nhân / caregiver); nullable nếu không phân biệt

`created_at`: TIMESTAMP

`updated_at`: TIMESTAMP

---

## 5. Health Habits

### Bảng `health_habits`

`habit_id`: UUID [PK]

`profile_id`: UUID [FK → profiles]

`habit_name`: VARCHAR(255) [NN]

`category_id`: UUID [FK]

`description`: TEXT

`target_time`: TIME

`status`: habit_status

`created_at`: TIMESTAMP

`updated_at`: TIMESTAMP

### Bảng `habit_categories`

`category_id`: UUID [PK]

`category_name`: VARCHAR(100) [NN]

`description`: TEXT

`created_at`: TIMESTAMP

### Bảng `habit_reminders`

`reminder_id`: UUID [PK]

`habit_id`: UUID [FK]

`reminder_time`: TIME [NN]

`repeat_frequency`: VARCHAR(50) [NN]

`repeat_interval`: INTEGER

`repeat_days`: VARCHAR(50)

`first_reminder_date`: DATE [NN]

`end_date`: DATE

`reminder_sound`: VARCHAR(100)

`status`: reminder_status

`created_at`: TIMESTAMP

`updated_at`: TIMESTAMP

### Bảng `habit_logs`

`log_id`: UUID [PK]

`habit_id`: UUID [FK]

`profile_id`: UUID [FK → profiles]

`scheduled_datetime`: TIMESTAMP [NN]

`actual_datetime`: TIMESTAMP

`status`: habit_log_status

`notes`: TEXT

`created_at`: TIMESTAMP

`updated_at`: TIMESTAMP

---

## 6. Caregiving & Collaboration

`patient_id` / `caregiver_id` / `created_by` / `member` / `added_by` đều là **FK → `profiles`**.

### Bảng `caregiver_patient_links`

`link_id`: UUID [PK]

`patient_id`: UUID [FK → profiles, NN]

`caregiver_id`: UUID [FK → profiles, NN]

`relationship`: VARCHAR(100)

`permission_level`: link_permission

`status`: link_status

`requested_at`: TIMESTAMP

`responded_at`: TIMESTAMP

`created_at`: TIMESTAMP

`updated_at`: TIMESTAMP

### Bảng `care_groups`

`group_id`: UUID [PK]

`group_name`: VARCHAR(255) [NN]

`description`: TEXT

`created_by_profile_id`: UUID [FK → profiles, NN]

`created_at`: TIMESTAMP

`updated_at`: TIMESTAMP

### Bảng `care_group_members`

`member_id`: UUID [PK]

`group_id`: UUID [FK, NN]

`profile_id`: UUID [FK → profiles, NN]

`role`: group_role

`joined_at`: TIMESTAMP

### Bảng `care_group_patients`

`id`: UUID [PK]

`group_id`: UUID [FK, NN]

`patient_id`: UUID [FK → profiles, NN]

`added_by_profile_id`: UUID [FK → profiles, NN]

`added_at`: TIMESTAMP

---

## 7. Reporting & System

### Bảng `compliance_reports`

`report_id`: UUID [PK]

`profile_id`: UUID [FK → profiles]

`report_type`: report_type [NN]

`period_start`: DATE [NN]

`period_end`: DATE [NN]

`total_scheduled`: INTEGER

`total_completed`: INTEGER

`total_missed`: INTEGER

`total_skipped`: INTEGER

`compliance_rate`: DECIMAL(5,2)

`generated_at`: TIMESTAMP

### Bảng `system_statistics`

`stat_id`: UUID [PK]

`stat_date`: DATE [UQ, NN]

`total_profiles`: INTEGER

`active_profiles`: INTEGER — ví dụ có sync trong cửa sổ thời gian

`new_profiles`: INTEGER — profile mới xuất hiện trên server trong ngày (theo quy ước sync)

`total_medical_records`: INTEGER

`total_medications`: INTEGER

`average_compliance_rate`: DECIMAL(5,2)

`created_at`: TIMESTAMP

### Bảng `notifications`

`notification_id`: UUID [PK]

`profile_id`: UUID [FK → profiles, NN]

`notification_type`: notification_type [NN]

`title`: VARCHAR(255) [NN]

`message`: TEXT [NN]

`related_id`: UUID

`is_read`: BOOLEAN

`read_at`: TIMESTAMP

`scheduled_for`: TIMESTAMP

`sent_at`: TIMESTAMP

`created_at`: TIMESTAMP

### Bảng `system_configs`

`config_id`: UUID [PK]

`config_key`: VARCHAR(100) [UQ, NN]

`config_value`: TEXT

`description`: TEXT

`updated_at`: TIMESTAMP

---

## 8. Gợi ý bổ sung khi triển khai sync (không bắt buộc)

- Cột **`updated_at` / `deleted_at` (soft delete)** trên các bảng đồng bộ để conflict resolution.
- Bảng **`sync_outbox`** trên client (SQLite/Isar) — không nhất thiết mirror sang Postgres nếu chỉ dùng phía app.
- Server có thể nhận **batch upsert** theo `profile_id` + version vector hoặc `updated_at` — chi tiết `(cần bổ sung)` theo stack thực tế.
