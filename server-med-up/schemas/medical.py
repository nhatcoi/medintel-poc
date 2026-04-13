from __future__ import annotations

from datetime import date

from pydantic import BaseModel, Field


class MedicalRecordCreate(BaseModel):
    profile_id: str
    disease_name: str
    category_id: str | None = None
    treatment_start_date: date
    treatment_status: str | None = None
    treatment_type: str | None = None
    notes: str | None = None


class MedicalRecordRead(BaseModel):
    record_id: str
    disease_name: str
    treatment_start_date: date
    treatment_status: str | None = None
    treatment_type: str | None = None
    notes: str | None = None


class MedicalRecordListResponse(BaseModel):
    records: list[MedicalRecordRead] = Field(default_factory=list)
