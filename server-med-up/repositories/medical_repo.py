from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from models.medical import MedicalRecord


def list_all(db: Session) -> list[MedicalRecord]:
    stmt = select(MedicalRecord).order_by(MedicalRecord.created_at.desc())
    return list(db.scalars(stmt).all())


def get_by_profile(db: Session, profile_id: uuid.UUID) -> list[MedicalRecord]:
    stmt = (
        select(MedicalRecord)
        .where(MedicalRecord.profile_id == profile_id)
        .order_by(MedicalRecord.treatment_start_date.desc())
    )
    return list(db.scalars(stmt).all())


def get_by_id(db: Session, record_id: uuid.UUID) -> MedicalRecord | None:
    return db.get(MedicalRecord, record_id)


def create(
    db: Session,
    *,
    profile_id: uuid.UUID,
    disease_name: str,
    treatment_start_date,
    treatment_status: str | None = None,
    treatment_type: str | None = None,
    notes: str | None = None,
):
    row = MedicalRecord(
        profile_id=profile_id,
        disease_name=disease_name,
        treatment_start_date=treatment_start_date,
        treatment_status=treatment_status,
        treatment_type=treatment_type,
        notes=notes,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def update(db: Session, row: MedicalRecord, **kwargs) -> MedicalRecord:
    for key, value in kwargs.items():
        if value is None:
            continue
        if hasattr(row, key):
            setattr(row, key, value)
    db.commit()
    db.refresh(row)
    return row


def delete(db: Session, row: MedicalRecord) -> None:
    db.delete(row)
    db.commit()
