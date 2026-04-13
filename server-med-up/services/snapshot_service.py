"""Patient agent context: build/refresh markdown snapshot."""

from __future__ import annotations

import uuid

from sqlalchemy.orm import Session

from models.agent_context import PatientAgentContext
from repositories import medication_repo, memory_repo, medical_repo


def build_snapshot_markdown(db: Session, profile_id: uuid.UUID) -> str:
    meds = medication_repo.get_medications_by_profile(db, profile_id)
    records = medical_repo.get_by_profile(db, profile_id)
    memory = memory_repo.get_all(db, profile_id)

    parts: list[str] = []

    if records:
        parts.append("## Benh an")
        for r in records:
            parts.append(f"- {r.disease_name} ({r.treatment_status or 'n/a'})")

    if meds:
        parts.append("## Tu thuoc")
        for m in meds:
            parts.append(f"- {m.medication_name}: {m.dosage or ''} / {m.frequency or ''}")

    if memory:
        parts.append("## Bo nho AI")
        for k, v in memory.items():
            parts.append(f"- {k}: {v}")

    return "\n".join(parts) or "(khong co du lieu)"


def refresh_context(db: Session, profile_id: uuid.UUID) -> PatientAgentContext:
    md = build_snapshot_markdown(db, profile_id)
    existing = db.get(PatientAgentContext, profile_id)
    if existing:
        existing.content_markdown = md
    else:
        existing = PatientAgentContext(profile_id=profile_id, content_markdown=md)
        db.add(existing)
    db.flush()
    return existing
