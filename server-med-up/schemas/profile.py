from __future__ import annotations

from datetime import date, datetime

from pydantic import BaseModel, Field


class ProfileCreate(BaseModel):
    full_name: str
    date_of_birth: date | None = None
    role: str = "patient"
    email: str | None = None
    phone_number: str | None = None
    emergency_contact: str | None = None


class ProfileOnboardingCreate(BaseModel):
    full_name: str
    date_of_birth: date | None = None
    email: str | None = None
    phone_number: str | None = None
    emergency_contact: str | None = None
    role: str = "patient"
    chronic_conditions: list[str] = Field(default_factory=list)
    allergies: list[str] = Field(default_factory=list)
    current_medications: list[str] = Field(default_factory=list)
    primary_diagnosis: str | None = None
    treatment_status: str | None = None
    medical_notes: str | None = None


class ProfileOnboardingUpdate(BaseModel):
    full_name: str | None = None
    date_of_birth: date | None = None
    email: str | None = None
    phone_number: str | None = None
    emergency_contact: str | None = None
    role: str | None = None
    chronic_conditions: list[str] | None = None
    allergies: list[str] | None = None
    current_medications: list[str] | None = None
    primary_diagnosis: str | None = None
    treatment_status: str | None = None
    medical_notes: str | None = None


class ProfileRead(BaseModel):
    profile_id: str
    full_name: str
    date_of_birth: date | None = None
    role: str
    email: str | None = None
    phone_number: str | None = None
    created_at: datetime


class ProfileUpdate(BaseModel):
    full_name: str | None = None
    date_of_birth: date | None = None
    role: str | None = None
    email: str | None = None
    phone_number: str | None = None
    emergency_contact: str | None = None


class ProfileListResponse(BaseModel):
    items: list[ProfileRead] = Field(default_factory=list)


class DeviceSetup(BaseModel):
    profile_id: str
    device_label: str | None = None
    platform: str | None = None
    sync_credential_hint: str | None = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    profile_id: str
