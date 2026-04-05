-- Xóa toàn bộ bảng tham chiếu dược / catalog DAV nếu tồn tại (PostgreSQL).
-- Sao lưu DB trước khi chạy. Thứ tự: con → cha; CASCADE gỡ FK từ bảng khác (nếu có).
--
-- Bảng: national_drugs, drug_basic_info, drug_registration_info,
--        pharmaceutical_companies, countries, drug_groups, dosage_forms, quality_standards

BEGIN;

ALTER TABLE IF EXISTS medications DROP COLUMN IF EXISTS national_drug_id;

DROP TABLE IF EXISTS drug_registration_info CASCADE;
DROP TABLE IF EXISTS drug_basic_info CASCADE;
DROP TABLE IF EXISTS national_drugs CASCADE;
DROP TABLE IF EXISTS pharmaceutical_companies CASCADE;
DROP TABLE IF EXISTS drug_groups CASCADE;
DROP TABLE IF EXISTS countries CASCADE;
DROP TABLE IF EXISTS dosage_forms CASCADE;
DROP TABLE IF EXISTS quality_standards CASCADE;

COMMIT;
