"""Quản lý bản markdown ngữ cảnh agent (patient_agent_context) — render từ snapshot SQL."""

from __future__ import annotations

import logging
import uuid
from datetime import UTC, datetime

from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.patient_agent_context import PatientAgentContext
from app.repositories.profile_repository import get_by_id
from app.services.patient_context_chunks import format_chunks_for_llm, snapshot_to_markdown_chunks
from app.services.patient_snapshot_service import build_patient_snapshot

_log = logging.getLogger("medintel.patient_agent_context")

# Bump khi đổi cấu trúc markdown → tự làm mới bản cũ.
FORMAT_VERSION = 1


def render_markdown_from_snapshot(db: Session, profile_id: uuid.UUID) -> str | None:
    """Tạo nội dung .md từ dữ liệu quan hệ (snapshot), không lưu DB."""
    snap = build_patient_snapshot(
        db,
        profile_id,
        log_limit=50,
        adherence_days=14,
    )
    if snap is None:
        return None
    now = datetime.now(UTC)
    header = (
        "# Ngữ cảnh agent — bệnh nhân (MedIntel)\n\n"
        "Nguồn: dữ liệu quan hệ trên server đã chuẩn hoá; không nhét raw JSON vào prompt chat.\n\n"
    )
    clock = f"## Mốc thời gian tham chiếu (UTC)\n`{now.isoformat()}`\n\n"
    chunks = snapshot_to_markdown_chunks(snap, redact_uuids=True)
    body = format_chunks_for_llm(
        chunks,
        max_total_chars=settings.patient_agent_context_max_markdown_chars,
    )
    return (header + clock + body).strip()


def upsert_agent_context_markdown(
    db: Session,
    profile_id: uuid.UUID,
    markdown: str,
    *,
    source: str = "snapshot_derived",
) -> PatientAgentContext:
    row = db.get(PatientAgentContext, profile_id)
    if row is None:
        row = PatientAgentContext(
            profile_id=profile_id,
            content_markdown=markdown,
            source=source,
            format_version=FORMAT_VERSION,
        )
        db.add(row)
    else:
        row.content_markdown = markdown
        row.source = source
        row.format_version = FORMAT_VERSION
    db.commit()
    db.refresh(row)
    return row


def refresh_stored_agent_context(
    db: Session, profile_id: uuid.UUID, *, source: str = "snapshot_derived"
) -> PatientAgentContext | None:
    """Render từ snapshot và ghi đè bảng patient_agent_context."""
    if get_by_id(db, profile_id) is None:
        return None
    md = render_markdown_from_snapshot(db, profile_id)
    if md is None:
        return None
    return upsert_agent_context_markdown(db, profile_id, md, source=source)


def get_context_for_chat(db: Session, profile_id: uuid.UUID) -> str | None:
    """Đọc markdown đã lưu; nếu trống / format cũ / quá hạn thì render lại và commit."""
    if get_by_id(db, profile_id) is None:
        return None
    row = db.get(PatientAgentContext, profile_id)
    now = datetime.now(UTC)
    max_age = max(60, settings.patient_agent_context_max_age_seconds)
    stale = True
    if row is not None:
        age = (now - row.updated_at).total_seconds()
        stale = row.format_version != FORMAT_VERSION or age > max_age
    if row is None or stale:
        refreshed = refresh_stored_agent_context(db, profile_id)
        if refreshed is None:
            return None
        _log.info(
            "patient_agent_context refreshed profile_id=%s chars=%s",
            profile_id,
            len(refreshed.content_markdown),
        )
        return refreshed.content_markdown
    return row.content_markdown


def get_stored_row(db: Session, profile_id: uuid.UUID) -> PatientAgentContext | None:
    return db.get(PatientAgentContext, profile_id)


def profile_id_for_medication(db: Session, medication_id: uuid.UUID) -> uuid.UUID | None:
    """profile_id sở hữu medication (qua treatment_period → medical_record)."""
    from app.models.medical import MedicalRecord, TreatmentPeriod
    from app.models.treatment_medication import Medication

    med = db.get(Medication, medication_id)
    if med is None:
        return None
    period = db.get(TreatmentPeriod, med.period_id)
    if period is None:
        return None
    rec = db.get(MedicalRecord, period.record_id)
    return rec.profile_id if rec else None


def refresh_patient_agent_context_best_effort(
    db: Session, profile_id: uuid.UUID | None,
) -> None:
    """Sau khi API đã commit thay đổi dữ liệu trong snapshot — làm mới markdown agent.

    Không ném exception: lỗi chỉ log để không làm fail request chính.
    """
    if profile_id is None:
        return
    try:
        refresh_stored_agent_context(db, profile_id)
    except Exception as exc:  # noqa: BLE001
        _log.warning(
            "patient_agent_context auto-refresh failed profile_id=%s: %s",
            profile_id,
            exc,
        )
        try:
            db.rollback()
        except Exception:
            pass
