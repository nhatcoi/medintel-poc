"""Ghép ngữ cảnh thuốc + snapshot bệnh nhân cho prompt LLM."""

from __future__ import annotations

import uuid

from sqlalchemy.orm import Session

from app.repositories.profile_repository import get_by_id
from app.schemas.chat import ChatRequest
from app.services.agent.medication_context import build_medication_context_block
from app.services.patient_agent_context_service import get_context_for_chat
from app.services.patient_context_chunks import format_chunks_for_llm, snapshot_to_markdown_chunks
from app.services.patient_snapshot_service import build_patient_snapshot


def resolve_profile_id(body: ChatRequest) -> uuid.UUID | None:
    if not (body.profile_id and body.profile_id.strip()):
        return None
    try:
        return uuid.UUID(body.profile_id.strip())
    except ValueError:
        return None


def _resolve_medication_context(
    db: Session, body: ChatRequest, profile_id: uuid.UUID | None
) -> str | None:
    if not body.include_medication_context or profile_id is None:
        return None
    if get_by_id(db, profile_id) is None:
        return None
    return build_medication_context_block(db, profile_id)


def resolve_combined_chat_context(
    db: Session, body: ChatRequest, profile_id: uuid.UUID | None
) -> str | None:
    """Medication block (có id cho tool) + tùy chọn snapshot đã chunk (không UUID)."""
    parts: list[str] = []
    med = _resolve_medication_context(db, body, profile_id)
    if med and med.strip():
        parts.append(med.strip())
    if (
        getattr(body, "include_patient_context_chunks", False)
        and profile_id is not None
        and get_by_id(db, profile_id) is not None
    ):
        blob: str | None = None
        if getattr(body, "patient_context_use_stored_md", True):
            blob = get_context_for_chat(db, profile_id)
        if not (blob and blob.strip()):
            snap = build_patient_snapshot(db, profile_id, log_limit=35, adherence_days=14)
            if snap is not None:
                ch = snapshot_to_markdown_chunks(snap, redact_uuids=True)
                blob = format_chunks_for_llm(ch, max_total_chars=4800)
        if blob and blob.strip():
            parts.append(
                "### Bối cảnh bệnh nhân (tri thức markdown trên server — không JSON)\n" + blob.strip()
            )
    if not parts:
        return None
    return "\n\n".join(parts)
