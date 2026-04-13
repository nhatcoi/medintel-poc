import uuid
from datetime import date

from fastapi import APIRouter, HTTPException

from api.deps import DbSession
from models.medical import MedicalRecord
from repositories import memory_repo, profile_repo
from schemas.profile import ProfileOnboardingCreate, ProfileOnboardingUpdate, ProfileRead

router = APIRouter(prefix="/profiles", tags=["profiles"])


def _to_profile_read(p) -> ProfileRead:
    return ProfileRead(
        profile_id=str(p.id),
        full_name=p.full_name,
        date_of_birth=p.date_of_birth,
        role=p.role,
        email=p.email,
        phone_number=p.phone_number,
        created_at=p.created_at,
    )


def _save_onboarding_medical_context(
    db: DbSession,
    *,
    profile_id: uuid.UUID,
    chronic_conditions: list[str] | None,
    allergies: list[str] | None,
    current_medications: list[str] | None,
    primary_diagnosis: str | None,
    treatment_status: str | None,
    medical_notes: str | None,
) -> None:
    if chronic_conditions is not None and len(chronic_conditions) > 0:
        memory_repo.upsert(
            db,
            profile_id,
            "chronic_conditions",
            [c.strip() for c in chronic_conditions if c.strip()],
            source="onboarding",
            confidence=1.0,
        )
    if allergies is not None and len(allergies) > 0:
        memory_repo.upsert(
            db,
            profile_id,
            "allergies",
            [a.strip() for a in allergies if a.strip()],
            source="onboarding",
            confidence=1.0,
        )
    if current_medications is not None and len(current_medications) > 0:
        memory_repo.upsert(
            db,
            profile_id,
            "current_medications",
            [m.strip() for m in current_medications if m.strip()],
            source="onboarding",
            confidence=0.95,
        )
    if medical_notes is not None and medical_notes.strip():
        memory_repo.upsert(
            db,
            profile_id,
            "lifestyle_notes",
            {"onboarding_medical_notes": medical_notes.strip()},
            source="onboarding",
            confidence=0.9,
        )

    if primary_diagnosis is not None and primary_diagnosis.strip():
        record = MedicalRecord(
            profile_id=profile_id,
            disease_name=primary_diagnosis.strip(),
            treatment_start_date=date.today(),
            treatment_status=(treatment_status or "active").strip(),
            treatment_type="onboarding",
            notes=(medical_notes or "").strip() or None,
        )
        db.add(record)


@router.post("/onboarding", response_model=ProfileRead)
def create_onboarding_profile(body: ProfileOnboardingCreate, db: DbSession):
    profile = profile_repo.create(
        db,
        full_name=body.full_name,
        role=body.role,
        date_of_birth=body.date_of_birth,
        email=body.email,
        phone_number=body.phone_number,
        emergency_contact=body.emergency_contact,
    )
    _save_onboarding_medical_context(
        db,
        profile_id=profile.id,
        chronic_conditions=body.chronic_conditions,
        allergies=body.allergies,
        current_medications=body.current_medications,
        primary_diagnosis=body.primary_diagnosis,
        treatment_status=body.treatment_status,
        medical_notes=body.medical_notes,
    )
    db.commit()
    db.refresh(profile)
    return _to_profile_read(profile)


@router.patch("/{profile_id}/onboarding", response_model=ProfileRead)
def update_onboarding_profile(profile_id: str, body: ProfileOnboardingUpdate, db: DbSession):
    try:
        pid = uuid.UUID(profile_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid UUID") from exc

    profile = profile_repo.get_by_id(db, pid)
    if profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")

    updated = profile_repo.update(
        db,
        profile,
        full_name=body.full_name,
        date_of_birth=body.date_of_birth,
        email=body.email,
        phone_number=body.phone_number,
        emergency_contact=body.emergency_contact,
        role=body.role,
    )
    _save_onboarding_medical_context(
        db,
        profile_id=updated.id,
        chronic_conditions=body.chronic_conditions,
        allergies=body.allergies,
        current_medications=body.current_medications,
        primary_diagnosis=body.primary_diagnosis,
        treatment_status=body.treatment_status,
        medical_notes=body.medical_notes,
    )
    db.commit()
    db.refresh(updated)
    return _to_profile_read(updated)


@router.get("/{profile_id}", response_model=ProfileRead)
def get_profile(profile_id: str, db: DbSession):
    try:
        pid = uuid.UUID(profile_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid UUID") from exc
    p = profile_repo.get_by_id(db, pid)
    if p is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    return _to_profile_read(p)
