from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from models.medical import MedicalRecord


def get_by_profile(db: Session, profile_id: uuid.UUID) -> list[MedicalRecord]:
    stmt = (
        select(MedicalRecord)
        .where(MedicalRecord.profile_id == profile_id)
        .order_by(MedicalRecord.treatment_start_date.desc())
    )
    return list(db.scalars(stmt).all())


def get_by_id(db: Session, record_id: uuid.UUID) -> MedicalRecord | None:
    return db.get(MedicalRecord, record_id)
