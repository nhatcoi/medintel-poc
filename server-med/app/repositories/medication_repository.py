"""Truy vấn thuốc theo profile (medical_records → treatment_periods → medications)."""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import time

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.medical import MedicalRecord, TreatmentPeriod
from app.models.treatment_medication import Medication, MedicationSchedule


@dataclass(frozen=True, slots=True)
class MedicationSummary:
    medication_id: uuid.UUID
    name: str
    dosage: str | None
    frequency: str | None
    instructions: str | None
    schedule_times: list[time]


def list_medications_for_profile(session: Session, profile_id: uuid.UUID) -> list[MedicationSummary]:
    stmt = (
        select(Medication)
        .join(TreatmentPeriod, Medication.period_id == TreatmentPeriod.id)
        .join(MedicalRecord, TreatmentPeriod.record_id == MedicalRecord.id)
        .where(MedicalRecord.profile_id == profile_id)
        .options(selectinload(Medication.schedules))
        .order_by(Medication.medication_name)
    )
    rows = session.scalars(stmt).unique().all()
    out: list[MedicationSummary] = []
    for med in rows:
        times = sorted({s.scheduled_time for s in (med.schedules or [])}, key=lambda t: (t.hour, t.minute))
        out.append(
            MedicationSummary(
                medication_id=med.id,
                name=(med.medication_name or "").strip() or "Chưa rõ",
                dosage=(med.dosage or "").strip() or None,
                frequency=(med.frequency or "").strip() or None,
                instructions=(med.instructions or "").strip() or None,
                schedule_times=times,
            )
        )
    return out
