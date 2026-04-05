#!/usr/bin/env bash
# Tạo .venv và cài dependency (tránh PEP 668 trên Python Homebrew).
set -e
cd "$(dirname "$0")"
if [ ! -d .venv ]; then
  echo "Tạo .venv…"
  python3 -m venv .venv
fi
echo "Cài requirements.txt…"
.venv/bin/python -m pip install -U pip
.venv/bin/python -m pip install -r requirements.txt
echo ""
echo "Xong. Kích hoạt:"
echo "  source .venv/bin/activate"
echo "Sau đó ví dụ:"
echo "  export DATABASE_URL=postgresql+psycopg2://medintel:medintel@localhost:5432/medintel_orm"
echo "  python3 dav_postgres_import.py --crawl --max-pages 1 --items-per-page 20"
