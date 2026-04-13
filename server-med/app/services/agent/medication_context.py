"""Bối cảnh thuốc (từ DB) ghép vào system prompt — hỗ trợ disambiguation tên thuốc."""

from __future__ import annotations

import uuid
from datetime import time

from sqlalchemy.orm import Session

from app.repositories.medication_repository import list_medications_for_profile


def _fmt_times(scheduled_times: list[time]) -> str:
    if not scheduled_times:
        return "—"
    return ", ".join(f"{t.hour:02d}:{t.minute:02d}" for t in scheduled_times)


def build_medication_context_block(db: Session, profile_id: uuid.UUID) -> str:
    meds = list_medications_for_profile(db, profile_id)
    if not meds:
        return (
            "### Thuốc đã lưu trên server (đơn quét / điều trị)\n"
            "Chưa có bản ghi. Gợi ý: thuốc có thể chưa đồng bộ vào database từ app."
        )
    lines: list[str] = [
        "### Thuốc đã lưu trên server (đơn quét / điều trị)",
        "Dùng danh sách này khi user nói chung chung (\"thuốc của tôi\", \"vừa uống thuốc\") "
        "để gợi ý chọn đúng tên hoặc map sang medication_name trong tool_calls.",
        "",
    ]
    for m in meds:
        t_str = _fmt_times(m.schedule_times)
        dose = (m.dosage or "").strip() or "—"
        lines.append(f"- **{m.name}** (id: `{m.medication_id}`) | liều: {dose} | giờ nhắc: {t_str}")
    return "\n".join(lines)
