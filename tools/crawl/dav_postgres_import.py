#!/usr/bin/env python3
"""
Đẩy dữ liệu DAV (JSON hoặc crawl trực tiếp) vào PostgreSQL theo schema server-med
(national_drugs, drug_basic_info, drug_registration_info, dosage_forms, quality_standards).

Chạy từ repo NCKH (hoặc bất kỳ đâu), cần DATABASE_URL — khuyến nghị file server-med/.env

Trên macOS thường không có lệnh `python` / `pip` — dùng `python3` và `python3 -m pip`
(hoặc tạo venv rồi `source .venv/bin/activate`).

  cd tools/crawl
  python3 -m venv .venv && source .venv/bin/activate
  python3 -m pip install -r requirements.txt
  export DATABASE_URL=postgresql+psycopg2://medintel:medintel@localhost:5432/medintel_orm
  python3 dav_postgres_import.py --crawl --max-pages 1 --items-per-page 20

Hoặc từ JSON đã crawl (thay tên file thật, không dùng ký tự ...):
  python3 dav_postgres_import.py --json data/dav_drugs_20250101.json

PEP 668 (Homebrew): không pip install vào Python hệ thống — chạy ./setup_venv.sh rồi source .venv/bin/activate

Crawl full ~53k bản ghi một lần (import theo trang, khuyến nghị):
  python3 dav_postgres_import.py --crawl --stream-pages --items-per-page 500 --delay 0.5

Cron — từng chunk (lưu next_skip trong file state):
  python3 dav_postgres_import.py --resume --items-per-page 500 --delay 1.0
  # hoặc: ./cron_import_chunk.sh
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import unicodedata
import uuid
from datetime import date, datetime
from pathlib import Path
from typing import Any

# server-med trên cùng repo
_ROOT = Path(__file__).resolve().parents[2]
_SERVER_MED = _ROOT / "server-med"
if str(_SERVER_MED) not in sys.path:
    sys.path.insert(0, str(_SERVER_MED))

try:
    from dotenv import load_dotenv
except ImportError:
    load_dotenv = None


def _load_env() -> None:
    env_path = _SERVER_MED / ".env"
    if load_dotenv and env_path.is_file():
        load_dotenv(env_path)
    if not os.environ.get("DATABASE_URL"):
        raise SystemExit(
            "Thiếu DATABASE_URL. Đặt biến môi trường hoặc tạo server-med/.env "
            "(vd. postgresql+psycopg2://medintel:medintel@localhost:5432/medintel_orm)"
        )


def _strip_diacritics(s: str) -> str:
    if not s:
        return ""
    nfd = unicodedata.normalize("NFD", s)
    return "".join(c for c in nfd if unicodedata.category(c) != "Mn")


def _parse_date(s: Any) -> date | None:
    if s is None or s == "":
        return None
    text = str(s).strip()
    if not text:
        return None
    try:
        if "T" in text:
            text = text.replace("Z", "+00:00")
            return datetime.fromisoformat(text).date()
        return date.fromisoformat(text[:10])
    except (ValueError, TypeError):
        return None


def _parse_json_list_str(raw: Any) -> list[dict[str, Any]]:
    """DAV hay nhét mảng object trong chuỗi JSON (urlHuongDanSuDung, urlNhan, …)."""
    if raw is None:
        return []
    if isinstance(raw, list):
        return [x for x in raw if isinstance(x, dict)]
    if isinstance(raw, str) and raw.strip():
        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            return []
        if isinstance(data, list):
            return [x for x in data if isinstance(x, dict)]
    return []


def _doc_entries(docs: list[dict[str, Any]], *, max_n: int = 25) -> list[dict[str, Any | None]]:
    out: list[dict[str, Any | None]] = []
    for d in docs[:max_n]:
        path = d.get("duongDanTep")
        desc = d.get("moTaTep")
        if path or desc:
            out.append(
                {
                    "path": str(path).strip()[:2000] if path else None,
                    "description": str(desc).strip()[:500] if desc else None,
                }
            )
    return out


def _extract_dav_documents(item: dict[str, Any]) -> dict[str, Any] | None:
    """Trích link tài liệu từ thongTinTaiLieu — cơ sở tải PDF / RAG sau này."""
    tl = item.get("thongTinTaiLieu")
    if not isinstance(tl, dict):
        return None
    result: dict[str, Any] = {}
    hdsd = _doc_entries(_parse_json_list_str(tl.get("urlHuongDanSuDung")))
    if hdsd:
        result["hdsd"] = hdsd
    label = _doc_entries(_parse_json_list_str(tl.get("urlNhan")))
    if label:
        result["label"] = label
    tccl = _doc_entries(_parse_json_list_str(tl.get("jsonTaiLieuTCCL")))
    if tccl:
        result["tccl"] = tccl
    return result if result else None


# Namespace cố định: cùng external_id DAV → cùng UUID trong DB (idempotent)
_DRUG_NS = uuid.uuid5(uuid.NAMESPACE_OID, "vn.gov.dav.medintel.national_drug")


def _drug_pk(external_id: int) -> uuid.UUID:
    return uuid.uuid5(_DRUG_NS, f"drug:{external_id}")


def _info_pk(external_id: int) -> uuid.UUID:
    return uuid.uuid5(_DRUG_NS, f"basic:{external_id}")


def _reg_pk(external_id: int) -> uuid.UUID:
    return uuid.uuid5(_DRUG_NS, f"reg:{external_id}")


def _get_or_create_dosage_form(session, form_name: str | None) -> int | None:
    if not form_name or not str(form_name).strip():
        return None
    name = str(form_name).strip()[:100]
    from sqlalchemy import select

    from app.models.drug_catalog import DosageForm

    row = session.scalars(select(DosageForm).where(DosageForm.form_name == name)).first()
    if row:
        return row.id
    df = DosageForm(form_name=name, description=None)
    session.add(df)
    session.flush()
    return df.id


def _get_or_create_quality_standard(session, code: str | None, std_name: str | None) -> int | None:
    code = (code or "").strip()[:20] or "DAV-UNK"
    name = (std_name or "").strip()[:255] or None
    from sqlalchemy import select

    from app.models.drug_catalog import QualityStandard

    row = session.scalars(select(QualityStandard).where(QualityStandard.standard_code == code)).first()
    if row:
        return row.id
    qs = QualityStandard(standard_code=code, standard_name=name, description=None)
    session.add(qs)
    session.flush()
    return qs.id


def upsert_dav_item(session, item: dict[str, Any]) -> str:
    """insert hoặc cập nhật một bản ghi DAV. Trả 'insert' | 'update' | 'skip'."""
    from sqlalchemy import delete, select

    from app.models.drug_catalog import (
        DrugBasicInfo,
        DrugRegistrationInfo,
        NationalDrug,
    )

    ext = item.get("id")
    if ext is None:
        return "skip"
    try:
        ext_id = int(ext)
    except (TypeError, ValueError):
        return "skip"

    drug_id = _drug_pk(ext_id)
    ten = (item.get("tenThuoc") or "").strip()
    if not ten:
        return "skip"

    so_dk = item.get("soDangKy")
    reg_num = str(so_dk).strip()[:50] if so_dk is not None and str(so_dk).strip() else None
    so_cu = item.get("soDangKyCu")
    old_reg = str(so_cu).strip()[:50] if so_cu is not None and str(so_cu).strip() else ""

    # DAV có nhiều id khác nhau cùng một số đăng ký → schema chỉ cho 1 dòng / registration_number
    drug = session.scalars(select(NationalDrug).where(NationalDrug.external_id == ext_id)).first()
    if drug is None and reg_num:
        drug = session.scalars(
            select(NationalDrug).where(NationalDrug.registration_number == reg_num)
        ).first()
    is_new = drug is None
    if drug is None:
        drug = NationalDrug(id=drug_id)
        session.add(drug)

    drug.registration_number = reg_num
    drug.old_registration_number = old_reg
    drug.drug_name = ten[:255]
    drug.drug_name_no_diacritics = _strip_diacritics(ten)[:255] or None
    ma = item.get("maThuoc")
    drug.drug_code = str(ma).strip()[:50] if ma else None
    drug.external_id = ext_id
    drug.group_id = None  # DAV nhomThuocId không trùng PK drug_groups nội bộ
    basic = item.get("thongTinThuocCoBan") or {}
    drug.type_id = basic.get("loaiThuocId") if basic.get("loaiThuocId") else None
    drug.is_active = bool(item.get("isActive", True))
    drug.is_expired = bool(item.get("isHetHan", False))
    drug.is_permitted = bool(item.get("isDuocPhep", False))
    rut = item.get("thongTinRutSoDangKy") or {}
    drug.is_registration_withdrawn = bool(rut.get("urlCongVanRutSoDangKy"))

    ghi = item.get("ghiChu")
    drug.dav_notes = str(ghi).strip()[:10000] if ghi is not None and str(ghi).strip() else None
    drug.dav_documents = _extract_dav_documents(item)

    session.flush()

    # basic info: 1-1 — xóa cũ theo drug_id rồi thêm (đơn giản, đúng với crawl lại)
    session.execute(delete(DrugBasicInfo).where(DrugBasicInfo.drug_id == drug.id))
    form_id = _get_or_create_dosage_form(session, basic.get("dangBaoChe"))
    std_code = str(basic.get("tieuChuanId") or "")[:20] or None
    std_name = basic.get("tieuChuan")
    std_id = _get_or_create_quality_standard(session, std_code or "DAV-UNK", std_name)

    hoat_chat = basic.get("hoatChatChinh")
    ham_luong = basic.get("hoatChatHamLuong")
    ham_luong2 = basic.get("hamLuong")
    conc_parts = [p for p in (ham_luong, ham_luong2) if p]
    concentration = " / ".join(str(p).strip() for p in conc_parts if str(p).strip())[:255] or None

    route_id: int | None = None
    ma_dd = basic.get("maDuongDung")
    if ma_dd is not None:
        try:
            route_id = int(ma_dd)
        except (TypeError, ValueError):
            route_id = None
    ten_dd = basic.get("tenDuongDung")
    admin_route = str(ten_dd).strip()[:255] if ten_dd is not None and str(ten_dd).strip() else None

    loai = basic.get("loaiThuoc")
    type_lbl = str(loai).strip()[:200] if loai is not None and str(loai).strip() else None
    nhom = basic.get("nhomThuoc")
    group_lbl = str(nhom).strip()[:255] if nhom is not None and str(nhom).strip() else None

    info = DrugBasicInfo(
        id=_info_pk(ext_id),
        drug_id=drug.id,
        active_ingredient=str(hoat_chat).strip()[:5000] if hoat_chat else None,
        concentration=concentration,
        form_id=form_id,
        route_id=route_id,
        administration_route_name=admin_route,
        drug_type_label=type_lbl,
        drug_group_label=group_lbl,
        packaging=str(basic.get("dongGoi")).strip()[:10000] if basic.get("dongGoi") else None,
        standard_id=std_id,
        shelf_life=str(basic.get("tuoiTho")).strip()[:50] if basic.get("tuoiTho") else None,
    )
    session.add(info)

    session.execute(delete(DrugRegistrationInfo).where(DrugRegistrationInfo.drug_id == drug.id))
    tt = item.get("thongTinDangKyThuoc") or {}
    if tt:
        reg = DrugRegistrationInfo(
            id=_reg_pk(ext_id),
            drug_id=drug.id,
            registration_issue_date=_parse_date(tt.get("ngayCapSoDangKy")),
            registration_renewal_date=_parse_date(tt.get("ngayGiaHanSoDangKy")),
            registration_expiry_date=_parse_date(tt.get("ngayHetHanSoDangKy")),
            decision_number=str(tt.get("soQuyetDinh")).strip()[:100] if tt.get("soQuyetDinh") else None,
            decision_url=str(tt.get("urlSoQuyetDinh")).strip()[:2000] if tt.get("urlSoQuyetDinh") else None,
            issue_batch=str(tt.get("dotCap")).strip()[:50] if tt.get("dotCap") else None,
            renewal_application_number=str(tt.get("soDonGiaHan")).strip()[:100]
            if tt.get("soDonGiaHan")
            else None,
            renewal_application_received=_parse_date(tt.get("ngayTiepNhanDonGiaHan")),
            renewal_receipt_url=str(rut.get("urlCongVanRutSoDangKy")).strip()[:2000]
            if rut.get("urlCongVanRutSoDangKy")
            else None,
        )
        session.add(reg)

    return "insert" if is_new else "update"


def import_items(items: list[dict[str, Any]], batch_commit: int = 100) -> tuple[int, int, int]:
    _load_env()
    # Import sau khi có DATABASE_URL trong môi trường
    from database.session import SessionLocal

    inserted = updated = skipped = 0
    db = SessionLocal()
    try:
        for i, item in enumerate(items):
            try:
                r = upsert_dav_item(db, item)
                if r == "insert":
                    inserted += 1
                elif r == "update":
                    updated += 1
                else:
                    skipped += 1
            except Exception as e:
                db.rollback()
                skipped += 1
                ext = item.get("id", "?")
                print(f"  Lỗi item id={ext}: {e}", file=sys.stderr)
            if batch_commit and (i + 1) % batch_commit == 0:
                db.commit()
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()
    return inserted, updated, skipped


def _default_state_path() -> Path:
    d = Path(__file__).resolve().parent / "data"
    d.mkdir(parents=True, exist_ok=True)
    return d / "dav_import_state.json"


def load_import_state(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {
            "next_skip": 0,
            "total_count": 0,
            "completed": False,
        }
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            return {"next_skip": 0, "total_count": 0, "completed": False}
        return data
    except (OSError, json.JSONDecodeError):
        return {"next_skip": 0, "total_count": 0, "completed": False}


def save_import_state(path: Path, state: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(state, ensure_ascii=False, indent=2), encoding="utf-8")


def run_resume_chunk(
    *,
    state_path: Path,
    items_per_page: int,
    delay: float,
    batch_commit: int,
) -> None:
    """Một lần chạy: fetch một trang DAV tại next_skip → import → cập nhật state."""
    _load_env()
    state = load_import_state(state_path)
    if state.get("completed"):
        print(
            "State đánh dấu đã xong. Xóa file state hoặc chạy với --reset-state để crawl lại từ đầu.",
            file=sys.stderr,
        )
        return

    next_skip = int(state.get("next_skip", 0))
    total_count = int(state.get("total_count", 0))

    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from crawl_dav_api import DavApiCrawler

    crawler = DavApiCrawler(output_dir="data")
    if delay > 0:
        import time

        time.sleep(delay)

    print(f"Resume: skip={next_skip}, lấy tối đa {items_per_page} bản ghi…")
    resp = crawler.fetch_page(next_skip, items_per_page)
    if not resp or not resp.get("success"):
        print("DAV API không thành công — giữ nguyên state, thử lại sau.", file=sys.stderr)
        return

    result = resp.get("result") or {}
    items = list(result.get("items") or [])
    api_total = int(result.get("totalCount") or 0)
    if api_total > 0:
        total_count = api_total

    if not items:
        if next_skip == 0:
            print("Không có dữ liệu (skip=0) — kiểm tra cookie/API DAV.", file=sys.stderr)
            return
        state["completed"] = True
        state["next_skip"] = next_skip
        state["total_count"] = total_count
        state["last_run_iso"] = datetime.now().isoformat(timespec="seconds")
        save_import_state(state_path, state)
        print("Không còn bản ghi — đánh dấu hoàn tất.")
        return

    print(f"Import {len(items)} bản ghi (tổng API: {total_count})…")
    ins, upd, sk = import_items(items, batch_commit=batch_commit)
    print(f"Xong batch: insert={ins}, update={upd}, skip={sk}")

    new_skip = next_skip + len(items)
    completed = bool(total_count > 0 and new_skip >= total_count)

    state["next_skip"] = new_skip
    state["total_count"] = total_count
    state["completed"] = completed
    state["last_run_iso"] = datetime.now().isoformat(timespec="seconds")
    state["last_batch_size"] = len(items)
    save_import_state(state_path, state)

    print(f"State: next_skip={new_skip}/{total_count}, completed={completed}")


def run_crawl_stream_import(
    *,
    max_pages: int | None,
    items_per_page: int,
    delay: float,
    batch_commit: int,
) -> None:
    """Crawl toàn bộ DAV theo trang, import Postgres sau mỗi trang (nhẹ RAM, phù hợp ~53k bản ghi)."""
    _load_env()
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from crawl_dav_api import DavApiCrawler

    crawler = DavApiCrawler(output_dir="data")
    skip_count = 0
    page = 1
    total_count: int | None = None
    t_ins = t_upd = t_sk = 0

    print("Crawl + import theo trang (stream) — DAV → Postgres…")

    while True:
        if max_pages is not None and page > max_pages:
            break

        print(f"Trang {page} (skip: {skip_count})…")
        resp = crawler.fetch_page(skip_count, items_per_page)
        if not resp or not resp.get("success"):
            print(f"Lỗi DAV ở trang {page} — dừng.", file=sys.stderr)
            raise SystemExit(1)

        result = resp.get("result") or {}
        items = list(result.get("items") or [])
        if total_count is None:
            total_count = int(result.get("totalCount") or 0)
            print(f"Tổng số bản ghi (API): {total_count}")

        if not items:
            if skip_count == 0:
                print("Không có dữ liệu (skip=0) — kiểm tra cookie/API DAV.", file=sys.stderr)
                raise SystemExit(1)
            print("Hết dữ liệu.")
            break

        print(f"  Import {len(items)} bản ghi…")
        ins, upd, sk = import_items(items, batch_commit=batch_commit)
        t_ins += ins
        t_upd += upd
        t_sk += sk
        print(f"  Batch: insert={ins}, update={upd}, skip={sk} | Lũy kế: {t_ins + t_upd + t_sk}/{total_count or '?'}")
        skip_count += len(items)

        if total_count and skip_count >= total_count:
            print("Đã xử lý đủ theo totalCount.")
            break

        page += 1
        if delay > 0:
            time.sleep(delay)

    print(
        f"\nHoàn tất stream: đã import qua DB — insert={t_ins}, update={t_upd}, skip={t_sk} "
        f"(offset cuối: {skip_count})"
    )


def load_json_items(path: Path) -> list[dict[str, Any]]:
    with path.open(encoding="utf-8") as f:
        data = json.load(f)
    if isinstance(data, list):
        return data
    if isinstance(data, dict) and "items" in data:
        return list(data["items"])
    raise ValueError("JSON phải là list hoặc object có key 'items'")


def main() -> None:
    parser = argparse.ArgumentParser(description="Import DAV drugs → PostgreSQL (MedIntel ORM)")
    parser.add_argument("--json", type=str, help="File JSON từ crawl (metadata.items)")
    parser.add_argument("--crawl", action="store_true", help="Crawl DAV rồi import (cần requests)")
    parser.add_argument(
        "--stream-pages",
        action="store_true",
        help="Với --crawl: import từng trang, không tích lũy ~53k item trong RAM (khuyến nghị crawl full)",
    )
    parser.add_argument(
        "--resume",
        action="store_true",
        help="Một chunk: đọc state → fetch DAV tại next_skip → import → ghi state (cho cron)",
    )
    parser.add_argument(
        "--state-file",
        type=str,
        default="",
        help="File JSON trạng thái (mặc định: tools/crawl/data/dav_import_state.json)",
    )
    parser.add_argument(
        "--reset-state",
        action="store_true",
        help="Xóa file state (--resume) rồi thoát; lần chạy sau bắt đầu skip=0",
    )
    parser.add_argument("--max-pages", type=int, default=None)
    parser.add_argument("--items-per-page", type=int, default=100)
    parser.add_argument("--delay", type=float, default=0.5)
    parser.add_argument("--batch-commit", type=int, default=100)
    args = parser.parse_args()

    state_path = Path(args.state_file) if args.state_file else _default_state_path()

    if args.reset_state:
        if state_path.is_file():
            state_path.unlink()
            print(f"Đã xóa state: {state_path}")
        else:
            print(f"Không có state: {state_path}")
        return

    if args.resume:
        if args.json:
            parser.error("--resume không dùng cùng --json")
        run_resume_chunk(
            state_path=state_path,
            items_per_page=args.items_per_page,
            delay=args.delay,
            batch_commit=args.batch_commit,
        )
        return

    if args.crawl:
        if args.stream_pages:
            run_crawl_stream_import(
                max_pages=args.max_pages,
                items_per_page=args.items_per_page,
                delay=args.delay,
                batch_commit=args.batch_commit,
            )
            return
        sys.path.insert(0, str(Path(__file__).resolve().parent))
        from crawl_dav_api import DavApiCrawler

        crawler = DavApiCrawler(output_dir="data")
        items = crawler.crawl_all(
            max_pages=args.max_pages,
            items_per_page=args.items_per_page,
            delay=args.delay,
        )
    elif args.json:
        items = load_json_items(Path(args.json))
    else:
        parser.error("Cần --json FILE, --crawl, hoặc --resume")

    print(f"Import {len(items)} bản ghi…")
    ins, upd, sk = import_items(items, batch_commit=args.batch_commit)
    print(f"Xong: insert={ins}, update={upd}, skip={sk}")


if __name__ == "__main__":
    main()
