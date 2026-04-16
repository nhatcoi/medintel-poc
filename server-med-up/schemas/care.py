from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class CareGroupCreate(BaseModel):
    group_name: str
    description: str | None = None
    created_by_profile_id: str


class CareGroupUpdate(BaseModel):
    group_name: str | None = None
    description: str | None = None


class CareGroupRead(BaseModel):
    group_id: str
    group_name: str
    description: str | None = None
    created_by_profile_id: str


class CareGroupMemberCreate(BaseModel):
    group_id: str
    profile_id: str
    role: str | None = None


class CareGroupMemberUpdate(BaseModel):
    role: str | None = None


class CareGroupMemberRead(BaseModel):
    member_id: str
    group_id: str
    profile_id: str
    role: str | None = None
    joined_at: datetime


class CareGroupPatientCreate(BaseModel):
    group_id: str
    patient_id: str
    added_by_profile_id: str
    consent_status: str | None = "granted"


class CareGroupPatientRead(BaseModel):
    id: str
    group_id: str
    patient_id: str
    added_by_profile_id: str
    added_at: datetime
    consent_status: str


class CaregiverPatientLinkCreate(BaseModel):
    patient_id: str
    caregiver_id: str
    relationship: str | None = None
    permission_level: str | None = None
    status: str | None = None


class CaregiverPatientLinkUpdate(BaseModel):
    relationship: str | None = None
    permission_level: str | None = None
    status: str | None = None
    responded_at: datetime | None = None


class CaregiverPatientLinkRead(BaseModel):
    link_id: str
    patient_id: str
    caregiver_id: str
    relationship: str | None = None
    permission_level: str | None = None
    status: str | None = None
    requested_at: datetime | None = None
    responded_at: datetime | None = None


class CareListResponse(BaseModel):
    items: list = Field(default_factory=list)

