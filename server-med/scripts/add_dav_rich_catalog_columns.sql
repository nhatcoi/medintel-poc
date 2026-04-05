-- Chạy một lần trên PostgreSQL nếu bảng đã tồn tại (create_all không ALTER cột cũ).
-- Sau đó chạy lại import DAV để đổ dữ liệu mới.

ALTER TABLE national_drugs
  ADD COLUMN IF NOT EXISTS dav_notes TEXT,
  ADD COLUMN IF NOT EXISTS dav_documents JSONB;

ALTER TABLE drug_basic_info
  ADD COLUMN IF NOT EXISTS administration_route_name VARCHAR(255),
  ADD COLUMN IF NOT EXISTS drug_type_label VARCHAR(200),
  ADD COLUMN IF NOT EXISTS drug_group_label VARCHAR(255);
