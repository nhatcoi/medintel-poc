#!/usr/bin/env python3
"""
Chạy song song nhiều worker crawl thuocbietduoc, mỗi worker 100 trang → 1 file riêng.
Có thể ingest từng file vào RAG ngay khi worker xong, không cần chờ toàn bộ.

Ví dụ:
  # 9 worker × 100 trang, bắt đầu từ trang 101 (đã có p2-p100 rồi)
  python crawl_parallel.py --workers 9 --chunk 100 --start 101

  # 20 worker × 100 trang từ trang 1
  python crawl_parallel.py --workers 20 --chunk 100 --start 1

  # Chạy xong tự ingest luôn vào DB
  python crawl_parallel.py --workers 9 --chunk 100 --start 101 --auto-ingest

Output: data/thuocbietduoc_p<from>_p<to>.json  (mỗi worker 1 file)
"""

from __future__ import annotations

import argparse
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

_SCRIPT_DIR = Path(__file__).resolve().parent
_CRAWL_SCRIPT = _SCRIPT_DIR / "crawl_thuocbietduoc_sample.py"
_SERVER_MED = _SCRIPT_DIR.parent.parent / "server-med"


def _output_path(page_from: int, page_to: int) -> Path:
    return _SCRIPT_DIR / "data" / f"thuocbietduoc_p{page_from}_p{page_to}.json"


def crawl_chunk(
    worker_id: int,
    page_from: int,
    page_to: int,
    *,
    delay: float,
    timeout: float,
    python: str,
    auto_ingest: bool,
) -> tuple[int, int, int, Path | None]:
    """
    Crawl page_from..page_to → file riêng.
    Trả về (worker_id, page_from, page_to, output_path | None).
    """
    out_path = _output_path(page_from, page_to)

    # Bỏ qua nếu file đã tồn tại (resume)
    if out_path.exists() and out_path.stat().st_size > 1024:
        print(f"[worker {worker_id}] SKIP trang {page_from}–{page_to} (file đã có: {out_path.name})", flush=True)
        if auto_ingest:
            _ingest(worker_id, out_path, python)
        return worker_id, page_from, page_to, out_path

    cmd = [
        python, str(_CRAWL_SCRIPT),
        "--page-from", str(page_from),
        "--page-to",   str(page_to),
        "--chi-tiet",
        "--delay",     str(delay),
        "--timeout",   str(timeout),
        "-o",          str(out_path),
    ]

    generous_timeout = int((page_to - page_from + 1) * 22 * (delay + 1.5))
    t0 = time.time()
    print(f"[worker {worker_id}] Bắt đầu trang {page_from}–{page_to}", flush=True)

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=generous_timeout)
        elapsed = time.time() - t0

        if result.returncode == 0 and out_path.exists():
            print(f"[worker {worker_id}] ✓ Xong trang {page_from}–{page_to} ({elapsed:.0f}s) → {out_path.name}", flush=True)
            if auto_ingest:
                _ingest(worker_id, out_path, python)
            return worker_id, page_from, page_to, out_path
        else:
            err = (result.stderr or "")[-300:]
            print(f"[worker {worker_id}] ✗ LỖI trang {page_from}–{page_to}: {err}", file=sys.stderr, flush=True)
            return worker_id, page_from, page_to, out_path if out_path.exists() else None

    except subprocess.TimeoutExpired:
        print(f"[worker {worker_id}] ✗ TIMEOUT trang {page_from}–{page_to}", file=sys.stderr, flush=True)
        return worker_id, page_from, page_to, out_path if out_path.exists() else None
    except Exception as e:
        print(f"[worker {worker_id}] ✗ EXCEPTION: {e}", file=sys.stderr, flush=True)
        return worker_id, page_from, page_to, None


def _ingest(worker_id: int, json_path: Path, python: str) -> None:
    """Gọi ai.rag.ingest trên file vừa crawl xong."""
    print(f"[worker {worker_id}] → Ingest {json_path.name} ...", flush=True)
    env_prefix = f'DATABASE_URL="postgresql+psycopg2://medintel:medintel@127.0.0.1:5432/medintel_orm"'
    cmd = [python, "-m", "ai.rag.ingest", str(json_path), "--batch-size", "64"]
    try:
        result = subprocess.run(
            cmd,
            capture_output=False,
            text=True,
            timeout=3600,
            cwd=str(_SERVER_MED),
            env={**__import__("os").environ, "DATABASE_URL": "postgresql+psycopg2://medintel:medintel@127.0.0.1:5432/medintel_orm"},
        )
        if result.returncode == 0:
            print(f"[worker {worker_id}] ✓ Ingest xong {json_path.name}", flush=True)
        else:
            print(f"[worker {worker_id}] ✗ Ingest lỗi {json_path.name}", file=sys.stderr, flush=True)
    except Exception as e:
        print(f"[worker {worker_id}] ✗ Ingest exception: {e}", file=sys.stderr, flush=True)


def main() -> None:
    p = argparse.ArgumentParser(description="Crawl song song thuocbietduoc — mỗi worker 1 file riêng.")
    p.add_argument("--workers",      type=int,   default=9,     help="Số luồng song song (mặc định 9)")
    p.add_argument("--chunk",        type=int,   default=100,   help="Số trang mỗi worker (mặc định 100)")
    p.add_argument("--start",        type=int,   default=101,   help="Trang bắt đầu (mặc định 101)")
    p.add_argument("--delay",        type=float, default=0.05,  help="Delay giữa request (mặc định 0.05s)")
    p.add_argument("--timeout",      type=float, default=30,    help="Timeout HTTP mỗi request (mặc định 30s)")
    p.add_argument("--auto-ingest",  action="store_true",       help="Tự ingest vào RAG DB khi mỗi worker xong")
    p.add_argument("--python",       default=sys.executable,    help="Path python (mặc định: python hiện tại)")
    args = p.parse_args()

    chunks = [
        (args.start + i * args.chunk, args.start + (i + 1) * args.chunk - 1)
        for i in range(args.workers)
    ]
    total_pages = args.workers * args.chunk
    end_page = chunks[-1][1]

    print(f"{'='*60}")
    print(f"Crawl {total_pages} trang ({args.start}–{end_page})")
    print(f"{args.workers} workers × {args.chunk} trang/worker")
    print(f"Delay: {args.delay}s | Timeout: {args.timeout}s")
    print(f"Output: data/thuocbietduoc_p<from>_p<to>.json (mỗi worker 1 file)")
    if args.auto_ingest:
        print(f"Auto-ingest: BẬT (ingest ngay khi mỗi worker xong)")
    print(f"{'='*60}\n")

    t0 = time.time()
    done_files: list[Path] = []
    failed: list[tuple[int, int]] = []

    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = {
            executor.submit(
                crawl_chunk, i, pf, pt,
                delay=args.delay,
                timeout=args.timeout,
                python=args.python,
                auto_ingest=args.auto_ingest,
            ): (pf, pt)
            for i, (pf, pt) in enumerate(chunks)
        }
        for future in as_completed(futures):
            wid, pf, pt, path = future.result()
            if path and path.exists():
                done_files.append(path)
            else:
                failed.append((pf, pt))

    elapsed = time.time() - t0
    print(f"\n{'='*60}")
    print(f"Xong: {len(done_files)}/{args.workers} workers thành công ({elapsed:.0f}s = {elapsed/60:.1f} phút)")
    print(f"Files: data/thuocbietduoc_p*.json")

    if failed:
        print(f"\nFailed ({len(failed)} workers):")
        for pf, pt in sorted(failed):
            print(f"  trang {pf}–{pt}")
        print("\nChạy lại để resume (file đã có sẽ bị bỏ qua tự động):")
        print(f"  python crawl_parallel.py --workers {args.workers} --chunk {args.chunk} --start {args.start}")

    if not args.auto_ingest and done_files:
        print(f"\nIngest từng file vào RAG:")
        print(f"  cd ../../server-med")
        for f in sorted(done_files):
            print(f"  DATABASE_URL=... .venv/bin/python -m ai.rag.ingest ../tools/crawl/{f.relative_to(_SCRIPT_DIR.parent.parent)} --batch-size 64")


if __name__ == "__main__":
    main()
