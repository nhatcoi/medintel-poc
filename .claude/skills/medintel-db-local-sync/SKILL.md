---
name: medintel-db-local-sync
description: >-
  Thiết kế và chỉnh schema MedIntel theo local-first: profiles thay users, không sessions/OTP,
  FK profile_id, devices tùy chọn, thống kê theo profile. Dùng khi sửa db-design.md, migration
  Postgres, API sync, hoặc khi user nhắc đồng bộ server, bỏ auth, UUID client.
---

# MedIntel DB — local-first & sync

## Nguồn chuẩn

- **`db-design.md`** (root repo): toàn bộ bảng và quy ước đặt tên sau khi lược IAM.

Khi mâu thuẫn với code cũ (JWT, `users`, `user_id`): ưu tiên **`db-design.md`** cho hướng mới; ghi rõ nếu backend Flutter vẫn đang transition.

## Quy ước cốt lõi

1. **`profile_id` (UUID):** tạo trên **client** lần đầu mở app / hoàn tất onboarding cục bộ; server chỉ lưu và merge theo id đó.
2. **Không** dùng trong schema giai đoạn này: `sessions`, `verification_codes`, `password_hash`, `google_id`, trạng thái tài khoản kiểu đăng nhập web.
3. Mọi thực thể “thuộc về người dùng” FK tới **`profiles`**, không dùng tên cột `user_id` trong tài liệu mới.
4. **`patient_id` / `caregiver_id`:** cùng kiểu — đều là `profiles.profile_id`; phân biệt bằng `role` và ngữ cảnh bảng link.
5. **Bảo mật sync** (token, HMAC, device binding): tầng API/app; không bắt buộc thể hiện đầy đủ trong ERD — có thể bảng `devices` chỉ lưu metadata + hash.

## Mapping từ thiết kế cũ

| Trước | Sau |
|-------|-----|
| `users` | `profiles` (bỏ cột auth) |
| `user_id` | `profile_id` |
| `logged_by` | `logged_by_profile_id` |
| `created_by` / `user_id` (care_group) | `created_by_profile_id` / `profile_id` |
| `total_users`, `active_users`, `new_users` | `total_profiles`, `active_profiles`, `new_profiles` |

## Khi agent viết SQL / migration

- Ưu tiên **`profile_id`** và ràng buộc FK tới `profiles(profile_id)`.
- Nếu user yêu cầu “giữ tương thích tạm” với API cũ: đề xuất **view** hoặc cột alias, không đổi nguồn sự thật trong doc mới.
- Conflict sync / soft delete: xem mục 8 trong `db-design.md`; nếu chưa có quyết định, ghi `(cần bổ sung)`.

## Liên quan skill khác

- **`/medintel-nckh`** — báo cáo, COM-B, pháp lý, `doc.md`.
- **`/agentic-medical-adherence`** — chat agentic, tool layer.
