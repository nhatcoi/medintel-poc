from __future__ import annotations

import uuid
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from models.memory import PatientMemory

CANONICAL_KEYS = frozenset({
    "current_medications",
    "allergies",
    "chronic_conditions",
    "reminder_preferences",
    "lifestyle_notes",
})


def get_all(db: Session, profile_id: uuid.UUID) -> dict[str, Any]:
    stmt = select(PatientMemory).where(PatientMemory.profile_id == profile_id)
    return {m.key: m.value for m in db.scalars(stmt).all()}


def get_one(db: Session, profile_id: uuid.UUID, key: str) -> Any | None:
    stmt = (
        select(PatientMemory)
        .where(PatientMemory.profile_id == profile_id, PatientMemory.key == key)
    )
    row = db.scalars(stmt).first()
    return row.value if row else None


def upsert(
    db: Session,
    profile_id: uuid.UUID,
    key: str,
    value: Any,
    source: str = "user",
    confidence: float = 1.0,
) -> PatientMemory:
    if not isinstance(value, (dict, list)):
        value = {"text": value}
    stmt = (
        select(PatientMemory)
        .where(PatientMemory.profile_id == profile_id, PatientMemory.key == key)
    )
    existing = db.scalars(stmt).first()
    if existing:
        existing.value = value
        existing.source = source
        existing.confidence = confidence
    else:
        existing = PatientMemory(
            profile_id=profile_id, key=key, value=value, source=source, confidence=confidence
        )
        db.add(existing)
    db.flush()
    return existing


def build_context_block(memory: dict[str, Any]) -> str:
    if not memory:
        return ""
    lines = ["### Bo nho dai han (AI)"]
    for k in CANONICAL_KEYS:
        if k in memory:
            lines.append(f"- **{k}**: {memory[k]}")
    for k, v in memory.items():
        if k not in CANONICAL_KEYS:
            lines.append(f"- {k}: {v}")
    return "\n".join(lines)
