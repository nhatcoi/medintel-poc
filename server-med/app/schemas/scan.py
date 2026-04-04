from __future__ import annotations

from pydantic import BaseModel, Field


class MedicationItem(BaseModel):
    name: str
    dosage: str | None = None
    frequency: str | None = None
    instructions: str | None = None
    times: list[str] = []


class ScanResult(BaseModel):
    doctor_name: str | None = None
    issued_date: str | None = None
    patient_name: str | None = None
    raw_text: str | None = None
    medications: list[MedicationItem] = []


class SavedMedicationRef(BaseModel):
    id: str
    name: str


class ScanPersistedResponse(ScanResult):
    """Giống kết quả LLM + id đã lưu DB."""

    prescription_id: str
    saved_medications: list[SavedMedicationRef] = Field(default_factory=list)
