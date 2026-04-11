"""Schema: hồ sơ bệnh án + danh mục bệnh."""

from __future__ import annotations

import uuid
from datetime import date, datetime

from pydantic import BaseModel, Field


# ── DiseaseCategory ──────────────────────────────────────────────────────

class DiseaseCategoryCreate(BaseModel):
    category_name: str
    description: str | None = None


class DiseaseCategoryRead(BaseModel):
    category_id: uuid.UUID
    category_name: str
    description: str | None = None

    model_config = {"from_attributes": True}


# ── MedicalRecord ────────────────────────────────────────────────────────

class MedicalRecordCreate(BaseModel):
    profile_id: uuid.UUID
    disease_name: str
    category_id: uuid.UUID | None = None
    treatment_start_date: date
    treatment_status: str | None = "active"
    treatment_type: str | None = None
    notes: str | None = None


class MedicalRecordUpdate(BaseModel):
    disease_name: str | None = None
    category_id: uuid.UUID | None = None
    treatment_status: str | None = None
    treatment_type: str | None = None
    notes: str | None = None


class MedicalRecordRead(BaseModel):
    record_id: uuid.UUID
    profile_id: uuid.UUID
    disease_name: str
    category_id: uuid.UUID | None = None
    treatment_start_date: date
    treatment_status: str | None = None
    treatment_type: str | None = None
    notes: str | None = None
    scan_image_url: str | None = None
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


class MedicalRecordListResponse(BaseModel):
    profile_id: uuid.UUID
    items: list[MedicalRecordRead] = Field(default_factory=list)
