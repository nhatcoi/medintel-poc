#!/usr/bin/env bash
# Tạo .venv (tránh PEP 668 trên Python Homebrew). Script mẫu chỉ cần stdlib.
set -e
cd "$(dirname "$0")"
if [ ! -d .venv ]; then
  echo "Tạo .venv…"
  python3 -m venv .venv
fi
if [ -f requirements.txt ] && grep -qvE '^\s*(#|$)' requirements.txt 2>/dev/null; then
  echo "Cài requirements.txt…"
  .venv/bin/python -m pip install -U pip
  .venv/bin/python -m pip install -r requirements.txt
else
  echo "Không có gói pip bắt buộc (crawl_thuocbietduoc_sample dùng stdlib)."
fi
echo ""
echo "Xong. Kích hoạt: source .venv/bin/activate"
echo "Ví dụ: python3 crawl_thuocbietduoc_sample.py --pages 1"
