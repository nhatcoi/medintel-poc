"""Schema: caregiver links, care groups."""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


# ── CaregiverPatientLink ─────────────────────────────────────────────────

class CareLinkCreate(BaseModel):
    patient_id: uuid.UUID
    caregiver_id: uuid.UUID
    relationship: str | None = None
    permission_level: str = "view"


class CareLinkUpdate(BaseModel):
    relationship: str | None = None
    permission_level: str | None = None
    status: str | None = None


class CareLinkRead(BaseModel):
    link_id: uuid.UUID
    patient_id: uuid.UUID
    caregiver_id: uuid.UUID
    relationship: str | None = None
    permission_level: str | None = None
    status: str | None = None
    requested_at: datetime | None = None
    responded_at: datetime | None = None

    model_config = {"from_attributes": True}


# ── CareGroup ────────────────────────────────────────────────────────────

class CareGroupCreate(BaseModel):
    group_name: str
    description: str | None = None
    created_by_profile_id: uuid.UUID


class CareGroupUpdate(BaseModel):
    group_name: str | None = None
    description: str | None = None


class CareGroupMemberAdd(BaseModel):
    profile_id: uuid.UUID
    role: str = "member"


class CareGroupPatientAdd(BaseModel):
    patient_id: uuid.UUID
    added_by_profile_id: uuid.UUID


class CareGroupMemberRead(BaseModel):
    member_id: uuid.UUID
    group_id: uuid.UUID
    profile_id: uuid.UUID
    role: str | None = None
    joined_at: datetime

    model_config = {"from_attributes": True}


class CareGroupPatientRead(BaseModel):
    id: uuid.UUID
    group_id: uuid.UUID
    patient_id: uuid.UUID
    added_by_profile_id: uuid.UUID
    added_at: datetime

    model_config = {"from_attributes": True}


class CareGroupRead(BaseModel):
    group_id: uuid.UUID
    group_name: str
    description: str | None = None
    created_by_profile_id: uuid.UUID
    members: list[CareGroupMemberRead] = Field(default_factory=list)
    patients: list[CareGroupPatientRead] = Field(default_factory=list)

    model_config = {"from_attributes": True}
