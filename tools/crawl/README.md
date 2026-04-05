# Crawl DAV → JSON / PostgreSQL

## Bắt buộc: virtualenv (macOS / Homebrew / PEP 668)

Python từ Homebrew thường báo **`externally-managed-environment`** nếu bạn chạy `pip install` trực tiếp — **phải dùng venv** (không nên `--break-system-packages`).

**Lần đầu** — chọn một trong hai:

```bash
cd tools/crawl
chmod +x setup_venv.sh
./setup_venv.sh
source .venv/bin/activate
```

Hoặc tay:

```bash
cd tools/crawl
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt
```

Lưu ý: **`source venv/bin/activate` chỉ chạy được sau khi đã tạo thư mục venv** (`python3 -m venv venv` hoặc `.venv` như trên). Nếu chưa tạo → `no such file`.

## `python` / `pip` không tìm thấy

Dùng **`python3`**; sau khi `source .venv/bin/activate` có thể dùng luôn `python` trong venv.

## Đừng copy dòng có `...`

Trong hướng dẫn cũ có đoạn `python3 dav_postgres_import.py ...` — **`...` không phải tham số thật**, argparse sẽ báo `unrecognized arguments`. Dùng lệnh đầy đủ, ví dụ:

```bash
python3 dav_postgres_import.py --crawl --max-pages 1 --items-per-page 50 --delay 0.5
```

## Import vào Postgres (`server-med` ORM)

Bật Postgres + tạo DB (vd. `medintel_orm`), chạy FastAPI một lần để có bảng, hoặc `create_all`.

```bash
source .venv/bin/activate
export DATABASE_URL=postgresql+psycopg2://medintel:medintel@localhost:5432/medintel_orm
python3 dav_postgres_import.py --crawl --max-pages 1 --items-per-page 50
```

Hoặc để script đọc `../../server-med/.env` (có `DATABASE_URL`).

## `run.sh` (tạo thư mục `venv/`)

```bash
./run.sh --test
```

Script tạo **`venv/`** (không phải `.venv`). Nếu bạn dùng `setup_venv.sh` thì thư mục là **`.venv`**.

## Cron — kéo dần cả danh mục (~53k bản ghi)

Mỗi lần chạy chỉ lấy **một “trang”** API (theo `items-per-page`), ghi `next_skip` vào `data/dav_import_state.json`. Lặp qua cron cho đến khi `completed: true`.

```bash
chmod +x cron_import_chunk.sh
# thử tay:
./cron_import_chunk.sh
# hoặc:
python3 dav_postgres_import.py --resume --items-per-page 500 --delay 1.0
```

Biến môi trường tùy chọn: `CRAWL_ITEMS_PER_PAGE` (mặc định 500), `CRAWL_DELAY` (1.0 s), `CRAWL_BATCH_COMMIT` (100).

**Bắt đầu lại từ đầu:** `python3 dav_postgres_import.py --reset-state` (xóa file state mặc định).

**Ví dụ crontab** (mỗi 15 phút, log ra file):

```cron
*/15 * * * * CRAWL_ITEMS_PER_PAGE=500 CRAWL_DELAY=1.0 /đường/dẫn/đầy/đủ/tools/crawl/cron_import_chunk.sh >> /đường/dẫn/tools/crawl/data/cron_dav_import.log 2>&1
```

Lưu ý: cookie/header DAV trong `crawl_dav_api.py` hết hạn thì chunk sẽ lỗi hoặc không có item — cần cập nhật và chạy lại.
