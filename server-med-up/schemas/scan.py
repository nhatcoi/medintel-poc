from __future__ import annotations

from pydantic import BaseModel, Field


class MedicationItem(BaseModel):
    medication_name: str
    active_ingredient: str | None = None
    strength: str | None = None
    dosage_form: str | None = None
    dosage: str | None = None
    frequency: str | None = None
    route: str | None = None
    duration_days: int | None = None
    instructions: str | None = None
    side_effects: str | None = None


class ScanResult(BaseModel):
    disease_name: str = ""
    prescribing_doctor: str | None = None
    prescription_date: str | None = None
    medications: list[MedicationItem] = Field(default_factory=list)


class ScanPersistedResponse(BaseModel):
    record_id: str
    period_id: str
    medication_ids: list[str]
