"""CRUD hồ sơ bệnh án + danh mục bệnh."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, HTTPException, Query
from sqlalchemy import select

from app.api.deps import DbSession
from app.models.medical import DiseaseCategory, MedicalRecord
from app.services.patient_agent_context_service import refresh_patient_agent_context_best_effort
from app.schemas.medical_records import (
    DiseaseCategoryCreate,
    DiseaseCategoryRead,
    MedicalRecordCreate,
    MedicalRecordListResponse,
    MedicalRecordRead,
    MedicalRecordUpdate,
)

router = APIRouter()


# ── DiseaseCategory ──────────────────────────────────────────────────────


@router.get("/categories", response_model=list[DiseaseCategoryRead])
def list_categories(db: DbSession):
    rows = db.scalars(select(DiseaseCategory).order_by(DiseaseCategory.category_name)).all()
    return [
        DiseaseCategoryRead(category_id=r.id, category_name=r.category_name, description=r.description)
        for r in rows
    ]


@router.post("/categories", response_model=DiseaseCategoryRead, status_code=201)
def create_category(body: DiseaseCategoryCreate, db: DbSession):
    cat = DiseaseCategory(category_name=body.category_name, description=body.description)
    db.add(cat)
    db.commit()
    db.refresh(cat)
    return DiseaseCategoryRead(category_id=cat.id, category_name=cat.category_name, description=cat.description)


# ── MedicalRecord ────────────────────────────────────────────────────────


@router.get("", response_model=MedicalRecordListResponse)
def list_records(db: DbSession, profile_id: uuid.UUID = Query(...)):
    rows = db.scalars(
        select(MedicalRecord)
        .where(MedicalRecord.profile_id == profile_id)
        .order_by(MedicalRecord.treatment_start_date.desc())
    ).all()
    items = [
        MedicalRecordRead(
            record_id=r.id,
            profile_id=r.profile_id,
            disease_name=r.disease_name,
            category_id=r.category_id,
            treatment_start_date=r.treatment_start_date,
            treatment_status=r.treatment_status,
            treatment_type=r.treatment_type,
            notes=r.notes,
            scan_image_url=r.scan_image_url,
            created_at=r.created_at,
        )
        for r in rows
    ]
    return MedicalRecordListResponse(profile_id=profile_id, items=items)


@router.post("", response_model=MedicalRecordRead, status_code=201)
def create_record(body: MedicalRecordCreate, db: DbSession):
    rec = MedicalRecord(
        profile_id=body.profile_id,
        disease_name=body.disease_name,
        category_id=body.category_id,
        treatment_start_date=body.treatment_start_date,
        treatment_status=body.treatment_status,
        treatment_type=body.treatment_type,
        notes=body.notes,
    )
    db.add(rec)
    db.commit()
    db.refresh(rec)
    refresh_patient_agent_context_best_effort(db, rec.profile_id)
    return MedicalRecordRead(
        record_id=rec.id,
        profile_id=rec.profile_id,
        disease_name=rec.disease_name,
        category_id=rec.category_id,
        treatment_start_date=rec.treatment_start_date,
        treatment_status=rec.treatment_status,
        treatment_type=rec.treatment_type,
        notes=rec.notes,
        scan_image_url=rec.scan_image_url,
        created_at=rec.created_at,
    )


@router.get("/{record_id}", response_model=MedicalRecordRead)
def get_record(record_id: uuid.UUID, db: DbSession):
    rec = db.get(MedicalRecord, record_id)
    if not rec:
        raise HTTPException(404, "Không tìm thấy hồ sơ bệnh án")
    return MedicalRecordRead(
        record_id=rec.id,
        profile_id=rec.profile_id,
        disease_name=rec.disease_name,
        category_id=rec.category_id,
        treatment_start_date=rec.treatment_start_date,
        treatment_status=rec.treatment_status,
        treatment_type=rec.treatment_type,
        notes=rec.notes,
        scan_image_url=rec.scan_image_url,
        created_at=rec.created_at,
    )


@router.patch("/{record_id}", response_model=MedicalRecordRead)
def update_record(record_id: uuid.UUID, body: MedicalRecordUpdate, db: DbSession):
    rec = db.get(MedicalRecord, record_id)
    if not rec:
        raise HTTPException(404, "Không tìm thấy hồ sơ bệnh án")
    for field, val in body.model_dump(exclude_unset=True).items():
        setattr(rec, field, val)
    db.commit()
    db.refresh(rec)
    refresh_patient_agent_context_best_effort(db, rec.profile_id)
    return MedicalRecordRead(
        record_id=rec.id,
        profile_id=rec.profile_id,
        disease_name=rec.disease_name,
        category_id=rec.category_id,
        treatment_start_date=rec.treatment_start_date,
        treatment_status=rec.treatment_status,
        treatment_type=rec.treatment_type,
        notes=rec.notes,
        scan_image_url=rec.scan_image_url,
        created_at=rec.created_at,
    )


@router.delete("/{record_id}", status_code=204)
def delete_record(record_id: uuid.UUID, db: DbSession):
    rec = db.get(MedicalRecord, record_id)
    if not rec:
        raise HTTPException(404, "Không tìm thấy hồ sơ bệnh án")
    pid = rec.profile_id
    db.delete(rec)
    db.commit()
    refresh_patient_agent_context_best_effort(db, pid)
