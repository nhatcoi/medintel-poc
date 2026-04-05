#!/usr/bin/env bash
# Một lần cron: import một chunk DAV (next_skip trong data/dav_import_state.json).
# Yêu cầu: tools/crawl/.venv + server-med/.env (DATABASE_URL) + cookie DAV còn hạn trong crawl_dav_api.py
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"
PY="$DIR/.venv/bin/python3"
if [[ ! -x "$PY" ]]; then
  PY="$DIR/.venv/bin/python"
fi
if [[ ! -x "$PY" ]]; then
  echo "Thiếu .venv — chạy: cd \"$DIR\" && ./setup_venv.sh" >&2
  exit 1
fi

ITEMS="${CRAWL_ITEMS_PER_PAGE:-500}"
DELAY="${CRAWL_DELAY:-1.0}"
BATCH="${CRAWL_BATCH_COMMIT:-100}"

exec "$PY" "$DIR/dav_postgres_import.py" \
  --resume \
  --items-per-page "$ITEMS" \
  --delay "$DELAY" \
  --batch-commit "$BATCH" \
  "$@"
