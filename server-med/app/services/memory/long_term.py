"""Long-term memory: CRUD patient_memory + format context block cho system prompt."""

from __future__ import annotations

import json
import uuid
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.patient_memory import PatientMemory

# Các key chuẩn hóa — LLM nên dùng đúng các khóa này (không đẻ key mới tùy tiện).
CANONICAL_KEYS: tuple[str, ...] = (
    "current_medications",  # list thuốc đang dùng
    "allergies",            # dị ứng đã biết
    "chronic_conditions",   # bệnh mạn tính
    "reminder_preferences", # giờ giấc / cách nhắc ưa thích
    "lifestyle_notes",      # thói quen ăn uống, sinh hoạt
)


def get_all_memory(db: Session, profile_id: uuid.UUID) -> dict[str, Any]:
    rows = (
        db.execute(
            select(PatientMemory).where(PatientMemory.profile_id == profile_id)
        )
        .scalars()
        .all()
    )
    return {r.key: r.value for r in rows}


def get_memory(db: Session, profile_id: uuid.UUID, key: str) -> Any | None:
    row = db.execute(
        select(PatientMemory).where(
            PatientMemory.profile_id == profile_id,
            PatientMemory.key == key,
        )
    ).scalar_one_or_none()
    return row.value if row else None


def upsert_memory(
    db: Session,
    profile_id: uuid.UUID,
    key: str,
    value: Any,
    *,
    source: str = "tool_call",
    confidence: float = 1.0,
) -> PatientMemory:
    """Ghi đè nếu đã có, không tạo duplicate. Caller tự quản lý commit ngoài nếu cần."""
    row = db.execute(
        select(PatientMemory).where(
            PatientMemory.profile_id == profile_id,
            PatientMemory.key == key,
        )
    ).scalar_one_or_none()
    if row is None:
        row = PatientMemory(
            profile_id=profile_id,
            key=key,
            value=value if isinstance(value, (dict, list)) else {"text": str(value)},
            source=source,
            confidence=confidence,
        )
        db.add(row)
    else:
        row.value = value if isinstance(value, (dict, list)) else {"text": str(value)}
        row.source = source
        row.confidence = confidence
    db.flush()
    return row


def build_memory_context_block(memory: dict[str, Any]) -> str | None:
    """Ghép patient_memory thành đoạn markdown ngắn cho system prompt."""
    if not memory:
        return None
    lines = [
        "### Bộ nhớ dài hạn (patient_memory)",
        "Dùng để cá nhân hóa câu trả lời. KHÔNG bịa thêm nếu khóa không có ở dưới.",
        "",
    ]
    for key in CANONICAL_KEYS:
        if key in memory:
            lines.append(f"- **{key}**: {_fmt_value(memory[key])}")
    # Key phi chuẩn (nếu có) hiển thị ở cuối
    for key, value in memory.items():
        if key in CANONICAL_KEYS:
            continue
        lines.append(f"- **{key}**: {_fmt_value(value)}")
    return "\n".join(lines)


def _fmt_value(value: Any) -> str:
    if isinstance(value, (dict, list)):
        try:
            return json.dumps(value, ensure_ascii=False)
        except (TypeError, ValueError):
            return str(value)
    return str(value)
