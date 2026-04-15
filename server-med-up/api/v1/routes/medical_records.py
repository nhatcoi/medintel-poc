import uuid

from fastapi import APIRouter, HTTPException, Query

from api.deps import DbSession
from repositories import medical_repo
from schemas.medical import MedicalRecordCreate, MedicalRecordListResponse, MedicalRecordRead, MedicalRecordUpdate

router = APIRouter(prefix="/medical-records", tags=["medical-records"])


@router.get("/", response_model=MedicalRecordListResponse)
def list_records(db: DbSession, profile_id: str = Query(...)):
    try:
        pid = uuid.UUID(profile_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid UUID") from exc
    records = medical_repo.get_by_profile(db, pid)
    return MedicalRecordListResponse(
        records=[
            MedicalRecordRead(
                record_id=str(r.id),
                disease_name=r.disease_name,
                treatment_start_date=r.treatment_start_date,
                treatment_status=r.treatment_status,
                treatment_type=r.treatment_type,
                notes=r.notes,
            )
            for r in records
        ]
    )


@router.post("/", response_model=MedicalRecordRead)
def create_record(body: MedicalRecordCreate, db: DbSession):
    try:
        pid = uuid.UUID(body.profile_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid profile UUID") from exc
    row = medical_repo.create(
        db,
        profile_id=pid,
        disease_name=body.disease_name,
        treatment_start_date=body.treatment_start_date,
        treatment_status=body.treatment_status,
        treatment_type=body.treatment_type,
        notes=body.notes,
    )
    return MedicalRecordRead(
        record_id=str(row.id),
        disease_name=row.disease_name,
        treatment_start_date=row.treatment_start_date,
        treatment_status=row.treatment_status,
        treatment_type=row.treatment_type,
        notes=row.notes,
    )


@router.get("/{record_id}", response_model=MedicalRecordRead)
def get_record(record_id: str, db: DbSession):
    try:
        rid = uuid.UUID(record_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid UUID") from exc
    row = medical_repo.get_by_id(db, rid)
    if row is None:
        raise HTTPException(status_code=404, detail="Medical record not found")
    return MedicalRecordRead(
        record_id=str(row.id),
        disease_name=row.disease_name,
        treatment_start_date=row.treatment_start_date,
        treatment_status=row.treatment_status,
        treatment_type=row.treatment_type,
        notes=row.notes,
    )


@router.patch("/{record_id}", response_model=MedicalRecordRead)
def update_record(record_id: str, body: MedicalRecordUpdate, db: DbSession):
    try:
        rid = uuid.UUID(record_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid UUID") from exc
    row = medical_repo.get_by_id(db, rid)
    if row is None:
        raise HTTPException(status_code=404, detail="Medical record not found")
    updated = medical_repo.update(
        db,
        row,
        disease_name=body.disease_name,
        treatment_start_date=body.treatment_start_date,
        treatment_status=body.treatment_status,
        treatment_type=body.treatment_type,
        notes=body.notes,
    )
    return MedicalRecordRead(
        record_id=str(updated.id),
        disease_name=updated.disease_name,
        treatment_start_date=updated.treatment_start_date,
        treatment_status=updated.treatment_status,
        treatment_type=updated.treatment_type,
        notes=updated.notes,
    )


@router.delete("/{record_id}")
def delete_record(record_id: str, db: DbSession):
    try:
        rid = uuid.UUID(record_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid UUID") from exc
    row = medical_repo.get_by_id(db, rid)
    if row is None:
        raise HTTPException(status_code=404, detail="Medical record not found")
    medical_repo.delete(db, row)
    return {"ok": True, "record_id": record_id}
