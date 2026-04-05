#!/bin/bash
# Chạy crawl_thuocbietduoc_sample.py trong virtual environment (thư mục venv/).

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if ! command -v python3 &> /dev/null; then
    print_error "Cần Python 3."
    exit 1
fi

if [ ! -d "venv" ]; then
    print_info "Tạo venv…"
    python3 -m venv venv
fi

# shellcheck source=/dev/null
source venv/bin/activate

if [ ! -f "crawl_thuocbietduoc_sample.py" ]; then
    print_error "Không thấy crawl_thuocbietduoc_sample.py trong $(pwd)"
    exit 1
fi

if [ -f "requirements.txt" ] && grep -qvE '^\s*(#|$)' requirements.txt 2>/dev/null; then
    VENV_PY="${SCRIPT_DIR}/venv/bin/python"
    print_info "Cài requirements.txt…"
    "$VENV_PY" -m pip install -U pip -q
    "$VENV_PY" -m pip install -r requirements.txt -q
fi

print_info "Chạy crawl_thuocbietduoc_sample.py…"
exec python crawl_thuocbietduoc_sample.py "$@"
