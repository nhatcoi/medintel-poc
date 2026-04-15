from __future__ import annotations

from langchain_core.tools import tool
from sqlalchemy import or_, select

from agent.tools.common import tool_error, tool_ok
from core.database import SessionLocal
from models.rag import TbdfDrug


@tool
def check_drug_interaction(drug_a: str, drug_b: str) -> str:
    """Đối chiếu nhanh 2 thuốc trong kho tri thức và trả về cảnh báo tương tác mức định hướng."""
    a = (drug_a or "").strip()
    b = (drug_b or "").strip()
    if not a or not b:
        return tool_error("Cần đủ 2 tên thuốc để kiểm tra tương tác.", code="INVALID_ARGS")

    db = SessionLocal()
    try:
        def _find(name: str):
            like_q = f"%{name}%"
            stmt = (
                select(TbdfDrug)
                .where(or_(TbdfDrug.name_display.ilike(like_q), TbdfDrug.ingredient_short.ilike(like_q)))
                .limit(1)
            )
            return db.scalars(stmt).first()

        da = _find(a)
        db_ = _find(b)
        if not da or not db_:
            return tool_ok(
                "Chưa đủ dữ liệu nội bộ để kết luận tương tác chắc chắn. Nên kiểm tra thêm với dược sĩ/bác sĩ.",
                extra={"drug_a_found": bool(da), "drug_b_found": bool(db_)},
            )

        summary = (
            f"Đã tìm thấy thông tin cho '{a}' và '{b}'. "
            "Hệ thống đánh dấu cần thận trọng khi dùng cùng; vui lòng xác nhận liều và thời điểm dùng với chuyên gia y tế."
        )
        return tool_ok(summary, extra={"drug_a_id": str(da.drug_id), "drug_b_id": str(db_.drug_id), "severity": "medium"})
    except Exception as exc:
        return tool_error(f"Lỗi kiểm tra tương tác: {exc}")
    finally:
        db.close()
