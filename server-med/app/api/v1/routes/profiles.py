"""CRUD hồ sơ cá nhân (profile)."""

from __future__ import annotations

import uuid
from datetime import date, datetime

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select

from app.api.deps import DbSession
from app.models.profile import Profile

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
    return ProfileRead(
        profile_id=p.id, full_name=p.full_name, date_of_birth=p.date_of_birth,
        emergency_contact=p.emergency_contact, role=p.role,
        email=p.email, phone_number=p.phone_number, created_at=p.created_at,
    )
