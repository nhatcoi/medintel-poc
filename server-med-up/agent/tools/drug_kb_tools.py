from __future__ import annotations

from langchain_core.tools import tool
from sqlalchemy import or_, select

from agent.tools.common import tool_error, tool_ok
from core.database import SessionLocal
from models.rag import TbdfDrug


@tool
def search_drug_kb(query: str) -> str:
    """Tim kiem thong tin thuoc theo ten/hoat chat trong kho RAG noi bo."""
    q = (query or "").strip()
    if not q:
        return tool_error("Thiếu từ khóa tra cứu thuốc.", code="INVALID_QUERY")

    db = SessionLocal()
    try:
        like_q = f"%{q}%"
        stmt = (
            select(TbdfDrug)
            .where(
                or_(
                    TbdfDrug.name_display.ilike(like_q),
                    TbdfDrug.ingredient_short.ilike(like_q),
                    TbdfDrug.registration_no.ilike(like_q),
                )
            )
            .limit(5)
        )
        rows = list(db.scalars(stmt).all())
        if not rows:
            return tool_ok(f"Không thấy kết quả nội bộ cho '{q}'.", extra={"items": []})

        items = [
            {
                "drug_id": str(r.drug_id),
                "name": r.name_display,
                "ingredient": r.ingredient_short,
                "registration_no": r.registration_no,
            }
            for r in rows
        ]
        return tool_ok(f"Tìm thấy {len(items)} kết quả cho '{q}'.", data_ref=str(rows[0].drug_id), extra={"items": items})
    except Exception as exc:
        return tool_error(f"Lỗi tra cứu thuốc: {exc}")
    finally:
        db.close()
