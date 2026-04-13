"""CRUD hồ sơ cá nhân (profile)."""

from __future__ import annotations

import uuid
from datetime import date, datetime

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select

from app.api.deps import DbSession
from app.models.profile import Profile
from app.schemas.patient_agent_context import PatientAgentContextRead
from app.schemas.profile_snapshot import ProfileSnapshotResponse
from app.services.patient_agent_context_service import (
    get_stored_row,
    refresh_patient_agent_context_best_effort,
    refresh_stored_agent_context,
)
from app.services.patient_snapshot_service import build_patient_snapshot

router = APIRouter()


class ProfileUpdate(BaseModel):
    full_name: str | None = None
    date_of_birth: date | None = None
    emergency_contact: str | None = None
    phone_number: str | None = None
    email: str | None = None


class ProfileRead(BaseModel):
    profile_id: uuid.UUID
    full_name: str
    date_of_birth: date | None = None
    emergency_contact: str | None = None
    role: str
    email: str | None = None
    phone_number: str | None = None
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


@router.get("/{profile_id}/snapshot", response_model=ProfileSnapshotResponse)
def get_profile_snapshot(
    profile_id: uuid.UUID,
    db: DbSession,
    logs_limit: int = Query(100, ge=1, le=500, description="Số log liều gần nhất"),
    adherence_days: int = Query(7, ge=1, le=60, description="Cửa sổ ngày cho tóm tắt tuân thủ"),
):
    """Gom một lần: hồ sơ, thiết bị, bệnh án, tủ thuốc + lịch, log liều, memory, tuân thủ."""
    out = build_patient_snapshot(
        db, profile_id, log_limit=logs_limit, adherence_days=adherence_days
    )
    if out is None:
        raise HTTPException(404, "Không tìm thấy hồ sơ")
    return out


def _agent_context_to_read(row) -> PatientAgentContextRead:
    md = row.content_markdown or ""
    return PatientAgentContextRead(
        profile_id=row.profile_id,
        content_markdown=md,
        source=row.source,
        format_version=row.format_version,
        updated_at=row.updated_at,
        char_count=len(md),
    )


@router.get("/{profile_id}/agent-context", response_model=PatientAgentContextRead)
def get_agent_context_markdown(profile_id: uuid.UUID, db: DbSession):
    """Đọc bản markdown ngữ cảnh agent đã lưu (giống file .md — không trả JSON snapshot)."""
    if db.get(Profile, profile_id) is None:
        raise HTTPException(404, "Không tìm thấy hồ sơ")
    row = get_stored_row(db, profile_id)
    if row is None:
        raise HTTPException(
            404,
            "Chưa có bản ngữ cảnh — dùng POST /profiles/{profile_id}/agent-context/refresh",
        )
    return _agent_context_to_read(row)


@router.post("/{profile_id}/agent-context/refresh", response_model=PatientAgentContextRead)
def refresh_agent_context_markdown(profile_id: uuid.UUID, db: DbSession):
    """Render lại markdown từ dữ liệu SQL (snapshot) và ghi vào patient_agent_context."""
    if db.get(Profile, profile_id) is None:
        raise HTTPException(404, "Không tìm thấy hồ sơ")
    row = refresh_stored_agent_context(db, profile_id)
    if row is None:
        raise HTTPException(500, "Không tạo được markdown từ snapshot")
    return _agent_context_to_read(row)


@router.get("/{profile_id}", response_model=ProfileRead)
def get_profile(profile_id: uuid.UUID, db: DbSession):
    p = db.get(Profile, profile_id)
    if not p:
        raise HTTPException(404, "Không tìm thấy hồ sơ")
    return ProfileRead(
        profile_id=p.id, full_name=p.full_name, date_of_birth=p.date_of_birth,
        emergency_contact=p.emergency_contact, role=p.role,
        email=p.email, phone_number=p.phone_number, created_at=p.created_at,
    )


@router.patch("/{profile_id}", response_model=ProfileRead)
def update_profile(profile_id: uuid.UUID, body: ProfileUpdate, db: DbSession):
    p = db.get(Profile, profile_id)
    if not p:
        raise HTTPException(404, "Không tìm thấy hồ sơ")
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(p, k, v)
    db.commit()
    db.refresh(p)
    refresh_patient_agent_context_best_effort(db, profile_id)
    return ProfileRead(
        profile_id=p.id, full_name=p.full_name, date_of_birth=p.date_of_birth,
        emergency_contact=p.emergency_contact, role=p.role,
        email=p.email, phone_number=p.phone_number, created_at=p.created_at,
    )
