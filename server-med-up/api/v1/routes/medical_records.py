import uuid

from fastapi import APIRouter, HTTPException, Query

from api.deps import DbSession
from repositories import medical_repo
from schemas.medical import MedicalRecordListResponse, MedicalRecordRead

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
