#!/usr/bin/env python3
"""
Pipeline nạp dữ liệu thuốc (JSON crawl) → tbdf_drugs → chunk → embed → tbdf_drug_chunks.

Chạy từ thư mục server-med:
  python -m ai.rag.ingest ../tools/crawl/data/thuocbietduoc_export_1.json
  python -m ai.rag.ingest ../tools/crawl/data/thuocbietduoc_export_1.json --batch-size 16 --skip-embed
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
import time
from pathlib import Path

from sqlalchemy import text as sa_text
from sqlalchemy.orm import Session

# -- Bootstrap: thêm server-med vào sys.path nếu chạy trực tiếp ----------
_SCRIPT_DIR = Path(__file__).resolve().parent
_SERVER_ROOT = _SCRIPT_DIR.parent.parent
if str(_SERVER_ROOT) not in sys.path:
    sys.path.insert(0, str(_SERVER_ROOT))

from app.core.config import settings
from app.core.db_bootstrap import ensure_postgres_database
from app.models.rag_drug import TbdfDrug, TbdfDrugChunk
from ai.rag.chunker import chunk_drug
from database.session import Base, engine, SessionLocal


def bump_kb_version(session) -> int:
    """Tăng kb_version trong system_configs → invalidate CAG cache tự động."""
    from app.models.reporting import SystemConfig

    row = session.query(SystemConfig).filter_by(config_key="kb_version").first()
    if row is None:
        new_ver = settings.kb_version + 1
        row = SystemConfig(
            config_key="kb_version",
            config_value=str(new_ver),
            description="RAG knowledge base version — dùng để invalidate CAG cache",
        )
        session.add(row)
    else:
        current = int(row.config_value or "1")
        new_ver = current + 1
        row.config_value = str(new_ver)
    session.commit()
    # Cập nhật in-memory settings để requests trong cùng process đọc đúng
    settings.kb_version = new_ver
    print(f"[ingest] kb_version → {new_ver} (CAG cache invalidated)")
    return new_ver


def _ensure_extensions(session: Session) -> None:
    """Tạo extension vector + pg_trgm nếu chưa có."""
    for ext in ("vector", "pg_trgm"):
        try:
            session.execute(sa_text(f"CREATE EXTENSION IF NOT EXISTS {ext}"))
            session.commit()
        except Exception as e:
            session.rollback()
            print(f"[warn] Không tạo được extension {ext}: {e}")


def _sha256(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()


def _normalize_text(drug: dict) -> str:
    """Ghép toàn bộ text của thuốc để tính hash thay đổi."""
    parts: list[str] = []
    parts.append(drug.get("ten", ""))
    chi_tiet = drug.get("chi_tiet_day_du") or {}
    for v in (chi_tiet.get("cac_phan_bo_sung") or {}).values():
        if isinstance(v, str):
            parts.append(v)
    for v in (chi_tiet.get("muc_lam_sang_html_ngan") or {}).values():
        if isinstance(v, str):
            parts.append(v)
    return "\n".join(parts)


def upsert_drug(session: Session, drug: dict) -> TbdfDrug:
    """Insert hoặc update tbdf_drugs, trả về ORM object."""
    ext_id = drug["id"]
    chi_tiet = drug.get("chi_tiet_day_du") or {}

    existing: TbdfDrug | None = (
        session.query(TbdfDrug)
        .filter_by(source_site="thuocbietduoc.com.vn", external_id=ext_id)
        .first()
    )

    norm = _normalize_text(drug)
    sha = _sha256(norm)

    info = chi_tiet.get("thong_tin_nhanh") or {}
    schema_prod = chi_tiet.get("schema_org_product") or {}

    if existing:
        existing.name_display = drug.get("ten") or existing.name_display
        existing.canonical_url = chi_tiet.get("url_chuan") or drug.get("url") or existing.canonical_url
        existing.slug = drug.get("slug") or existing.slug
        existing.registration_no = drug.get("so_dang_ky") or existing.registration_no
        existing.dosage_form = drug.get("dang_bao_che") or existing.dosage_form
        existing.ingredient_short = chi_tiet.get("thanh_phan_ngan") or existing.ingredient_short
        existing.category = info.get("Danh muc") or schema_prod.get("danh_muc") or existing.category
        existing.raw_document = drug
        existing.normalized_text = norm
        existing.text_sha256 = sha
        return existing

    row = TbdfDrug(
        source_site="thuocbietduoc.com.vn",
        external_id=ext_id,
        canonical_url=chi_tiet.get("url_chuan") or drug.get("url", ""),
        slug=drug.get("slug"),
        name_display=drug.get("ten", f"drug-{ext_id}"),
        registration_no=drug.get("so_dang_ky"),
        dosage_form=drug.get("dang_bao_che"),
        ingredient_short=chi_tiet.get("thanh_phan_ngan"),
        category=info.get("Danh mục") or schema_prod.get("danh_muc"),
        raw_document=drug,
        normalized_text=norm,
        text_sha256=sha,
    )
    session.add(row)
    return row


def ingest_chunks(
    session: Session,
    drug_row: TbdfDrug,
    drug: dict,
    *,
    skip_embed: bool = False,
    batch_size: int = 16,
) -> int:
    """Chunk + embed + lưu tbdf_drug_chunks. Trả về số chunk đã tạo."""
    from ai.rag.chunker import chunk_drug as do_chunk

    chunks = do_chunk(drug)
    if not chunks:
        return 0

    # Xóa chunk cũ
    session.query(TbdfDrugChunk).filter_by(drug_id=drug_row.drug_id).delete()
    session.flush()

    # Embed theo batch
    embeddings: list[list[float] | None] = [None] * len(chunks)
    if not skip_embed:
        from ai.rag.embedding import get_embeddings_sync

        texts = [c.content for c in chunks]
        for i in range(0, len(texts), batch_size):
            batch = texts[i : i + batch_size]
            try:
                vecs = get_embeddings_sync(batch)
                for j, vec in enumerate(vecs):
                    embeddings[i + j] = vec
            except Exception as e:
                print(f"  [embed error batch {i}] {e}", file=sys.stderr)

    for idx, chunk in enumerate(chunks):
        row = TbdfDrugChunk(
            drug_id=drug_row.drug_id,
            chunk_ordinal=idx,
            section=chunk.section,
            content=chunk.content,
            token_estimate=chunk.token_estimate,
            embedding_model=settings.embedding_model,
            embedding=embeddings[idx],
        )
        session.add(row)

    return len(chunks)


def run(json_path: str, *, batch_size: int = 16, skip_embed: bool = False) -> None:
    path = Path(json_path)
    if not path.exists():
        raise SystemExit(f"File không tồn tại: {path}")

    data = json.loads(path.read_text("utf-8"))
    drugs = data.get("thuoc") or []
    if not drugs:
        raise SystemExit("Không tìm thấy mảng 'thuoc' trong JSON.")

    print(f"[ingest] {len(drugs)} thuốc từ {path.name}")

    ensure_postgres_database(settings.database_url)
    _ensure_extensions(SessionLocal())

    # Tạo bảng nếu chưa có
    Base.metadata.create_all(bind=engine)

    total_chunks = 0
    session = SessionLocal()
    try:
        for i, drug in enumerate(drugs):
            label = drug.get("ten") or drug.get("id", "?")
            print(f"  [{i + 1}/{len(drugs)}] {label}", end=" ", flush=True)

            if drug.get("chi_tiet_day_du", {}).get("loi"):
                print("— bỏ qua (lỗi crawl)")
                continue

            drug_row = upsert_drug(session, drug)
            session.flush()

            n = ingest_chunks(session, drug_row, drug, skip_embed=skip_embed, batch_size=batch_size)
            total_chunks += n
            print(f"→ {n} chunks")

            session.commit()

    except KeyboardInterrupt:
        session.commit()
        print("\n[ingest] Ctrl+C — đã commit phần đã xử lý.")
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()

    print(f"[ingest] Xong: {len(drugs)} thuốc, {total_chunks} chunks tổng cộng.")


def main() -> None:
    p = argparse.ArgumentParser(description="Nạp JSON thuốc → Postgres + pgvector.")
    p.add_argument("json_file", help="Đường dẫn file thuocbietduoc_export_*.json")
    p.add_argument("--batch-size", type=int, default=16, help="Số text gửi embed cùng lúc (mặc định 16)")
    p.add_argument("--skip-embed", action="store_true", help="Chỉ nạp text, không gọi embedding API")
    args = p.parse_args()
    run(args.json_file, batch_size=args.batch_size, skip_embed=args.skip_embed)


if __name__ == "__main__":
    main()
