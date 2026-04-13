"""Node 2: Load patient context from DB into state."""

from __future__ import annotations

import uuid

from sqlalchemy.orm import Session

from agent.state import PatientState
from core.database import SessionLocal
from repositories import medication_repo, memory_repo, medical_repo


async def context_loader(state: PatientState) -> dict:
    profile_id_str = state.get("profile_id")
    if not profile_id_str:
        return {}

    try:
        pid = uuid.UUID(profile_id_str)
    except ValueError:
        return {}

    db: Session = SessionLocal()
    try:
        meds = medication_repo.get_medications_by_profile(db, pid)
        med_dicts = [
            {
                "medication_id": str(m.id),
                "name": m.medication_name,
                "dosage": m.dosage,
                "frequency": m.frequency,
                "instructions": m.instructions,
                "status": m.status,
            }
            for m in meds
        ]

        records = medical_repo.get_by_profile(db, pid)
        patient_info = {
            "profile_id": profile_id_str,
            "diseases": [
                {"name": r.disease_name, "status": r.treatment_status}
                for r in records
            ],
        }

        memory = memory_repo.get_all(db, pid)

        return {
            "patient_info": patient_info,
            "medications": med_dicts,
            "memory": memory,
        }
    finally:
        db.close()
