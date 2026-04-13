-- Dữ liệu mẫu cho snapshot API — profile Nhat Nhat (từ app).
-- DB: medintel_orm, user medintel
--
-- Chạy:
--   PGPASSWORD=medintel psql -h localhost -p 5432 -U medintel -d medintel_orm -f scripts/seed_profile_snapshot_sample.sql
--
-- Idempotent: xóa chuỗi bản ghi mẫu (UUID cố định bên dưới) rồi INSERT lại.

BEGIN;

-- UUID cố định (mẫu snapshot)
-- Đảm bảo profile tồn tại (đã có từ app thì INSERT bỏ qua)
INSERT INTO profiles (profile_id, full_name, role, email, created_at, updated_at)
VALUES (
  'fef71594-5470-442d-9fec-c76cab34ceb7'::uuid,
  'Nhat Nhat',
  'patient',
  '77caf4e8@device.local',
  now(),
  now()
)
ON CONFLICT (profile_id) DO NOTHING;

-- Xóa mẫu cũ (thứ tự FK)
DELETE FROM medication_logs WHERE log_id IN (
  '22222222-2222-4222-8222-222222222201'::uuid,
  '22222222-2222-4222-8222-222222222202'::uuid
);
DELETE FROM medication_schedules WHERE schedule_id IN (
  '33333333-3333-4333-8333-333333333301'::uuid,
  '33333333-3333-4333-8333-333333333302'::uuid,
  '33333333-3333-4333-8333-333333333303'::uuid
);
DELETE FROM medications WHERE medication_id IN (
  '44444444-4444-4444-8444-444444444401'::uuid,
  '44444444-4444-4444-8444-444444444402'::uuid
);
DELETE FROM treatment_periods WHERE period_id = '55555555-5555-4555-8555-555555555501'::uuid;
DELETE FROM medical_records WHERE record_id = '66666666-6666-4666-8666-666666666601'::uuid;
DELETE FROM patient_memory WHERE memory_id = '77777777-7777-4777-8777-777777777701'::uuid;
DELETE FROM devices WHERE device_id = '88888888-8888-4888-8888-888888888801'::uuid;

-- Bệnh án + đợt điều trị
INSERT INTO medical_records (
  record_id, profile_id, disease_name, treatment_start_date,
  treatment_status, treatment_type, notes, created_at, updated_at
) VALUES (
  '66666666-6666-4666-8666-666666666601'::uuid,
  'fef71594-5470-442d-9fec-c76cab34ceb7'::uuid,
  'Tăng huyết áp (mẫu)',
  '2026-01-15',
  'active',
  'long_term',
  'Bản ghi demo cho GET /profiles/.../snapshot',
  now(),
  now()
);

INSERT INTO treatment_periods (
  period_id, record_id, period_name, start_date, status, notes, created_at, updated_at
) VALUES (
  '55555555-5555-4555-8555-555555555501'::uuid,
  '66666666-6666-4666-8666-666666666601'::uuid,
  'Đợt điều trị hiện tại (mẫu)',
  '2026-01-15',
  'active',
  NULL,
  now(),
  now()
);

-- Tủ thuốc: 2 thuốc + lịch uống
INSERT INTO medications (
  medication_id, period_id, medication_name, dosage, frequency, instructions,
  start_date, end_date, status, remaining_quantity, quantity_unit,
  prescribing_doctor, notes, created_at, updated_at
) VALUES (
  '44444444-4444-4444-8444-444444444401'::uuid,
  '55555555-5555-4555-8555-555555555501'::uuid,
  'Amlodipine',
  '5 mg',
  '1 lần/ngày',
  'Uống sau ăn sáng',
  '2026-01-15',
  NULL,
  'active',
  28,
  'viên',
  'BS. Demo',
  'Thuốc mẫu — snapshot',
  now(),
  now()
),
(
  '44444444-4444-4444-8444-444444444402'::uuid,
  '55555555-5555-4555-8555-555555555501'::uuid,
  'Paracetamol',
  '500 mg',
  'khi sốt',
  'Không quá 4 g/ngày',
  '2026-02-01',
  NULL,
  'active',
  10,
  'viên',
  NULL,
  'Thuốc mẫu — snapshot',
  now(),
  now()
);

INSERT INTO medication_schedules (
  schedule_id, medication_id, scheduled_time, repeat_pattern, status,
  reminder_enabled, created_at, updated_at
) VALUES
(
  '33333333-3333-4333-8333-333333333301'::uuid,
  '44444444-4444-4444-8444-444444444401'::uuid,
  '08:00'::time,
  'daily',
  'active',
  true,
  now(),
  now()
),
(
  '33333333-3333-4333-8333-333333333302'::uuid,
  '44444444-4444-4444-8444-444444444401'::uuid,
  '20:00'::time,
  'daily',
  'active',
  true,
  now(),
  now()
),
(
  '33333333-3333-4333-8333-333333333303'::uuid,
  '44444444-4444-4444-8444-444444444402'::uuid,
  '12:00'::time,
  'daily',
  'active',
  true,
  now(),
  now()
);

-- Log liều mẫu (2 dòng)
INSERT INTO medication_logs (
  log_id, schedule_id, profile_id, scheduled_datetime, actual_datetime,
  status, notes, logged_by_profile_id, created_at, updated_at
) VALUES (
  '22222222-2222-4222-8222-222222222201'::uuid,
  '33333333-3333-4333-8333-333333333301'::uuid,
  'fef71594-5470-442d-9fec-c76cab34ceb7'::uuid,
  (now() - interval '2 hours'),
  (now() - interval '1 hours 55 minutes'),
  'taken',
  'demo_seed_snapshot',
  'fef71594-5470-442d-9fec-c76cab34ceb7'::uuid,
  now(),
  now()
),
(
  '22222222-2222-4222-8222-222222222202'::uuid,
  '33333333-3333-4333-8333-333333333303'::uuid,
  'fef71594-5470-442d-9fec-c76cab34ceb7'::uuid,
  (now() - interval '30 minutes'),
  NULL,
  'missed',
  'demo_seed_snapshot',
  'fef71594-5470-442d-9fec-c76cab34ceb7'::uuid,
  now(),
  now()
);

-- Bộ nhớ mẫu (KV)
INSERT INTO patient_memory (
  memory_id, profile_id, key, value, source, confidence, created_at, updated_at
) VALUES (
  '77777777-7777-4777-8777-777777777701'::uuid,
  'fef71594-5470-442d-9fec-c76cab34ceb7'::uuid,
  'allergies',
  '{"known": ["phấn hoa nhẹ"], "note": "mẫu snapshot"}'::jsonb,
  'demo_seed',
  0.9,
  now(),
  now()
);

-- Thiết bị mẫu
INSERT INTO devices (
  device_id, profile_id, device_label, platform, last_seen_at, created_at, updated_at
) VALUES (
  '88888888-8888-4888-8888-888888888801'::uuid,
  'fef71594-5470-442d-9fec-c76cab34ceb7'::uuid,
  'iPhone demo',
  'ios',
  now(),
  now(),
  now()
);

COMMIT;
