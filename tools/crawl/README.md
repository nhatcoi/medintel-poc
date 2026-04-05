# Crawl mẫu thuốc (Thuốc Biệt Dược)

Thư mục chỉ còn script **`crawl_thuocbietduoc_sample.py`**: cào danh sách/chi tiết từ thuocbietduoc.com.vn, ghi JSON (không import Postgres, không pipeline DAV).

## Virtualenv (macOS / Homebrew / PEP 668)

Script chỉ dùng thư viện chuẩn Python; venv là tùy chọn nhưng nên dùng nếu bạn cài thêm gói sau này.

```bash
cd tools/crawl
python3 -m venv .venv
source .venv/bin/activate
```

Hoặc:

```bash
chmod +x setup_venv.sh
./setup_venv.sh
source .venv/bin/activate
```

## Chạy

```bash
python3 crawl_thuocbietduoc_sample.py --pages 1
python3 crawl_thuocbietduoc_sample.py --pages 1 --chi-tiet --limit 5 --delay 1.5
```

File mặc định: `data/thuocbietduoc_export_<pages>.json` (khi có `--chi-tiet` và không chỉ `-o`).

## Gỡ bảng tham chiếu dược / catalog trên Postgres

Script xóa (nếu tồn tại): `national_drugs`, `drug_basic_info`, `drug_registration_info`, `pharmaceutical_companies`, `countries`, `drug_groups`, `dosage_forms`, `quality_standards`, và cột `medications.national_drug_id`. Chạy sau khi backup:

```bash
# Chuỗi kết nối dạng postgresql://user:pass@host:port/db (không dùng tiền tố sqlalchemy +psycopg2).
psql "postgresql://medintel:medintel@localhost:5432/medintel_orm" -f ../../server-med/scripts/drop_dav_national_drug_catalog.sql
```

(hoặc `-f` trỏ đúng đường dẫn tới `server-med/scripts/drop_dav_national_drug_catalog.sql`).

## `run.sh`

Tạo `venv/` và chạy mẫu; mọi tham số truyền tiếp cho `crawl_thuocbietduoc_sample.py`:

```bash
./run.sh --pages 1
./run.sh --pages 1 --chi-tiet --delay 1.0
```
