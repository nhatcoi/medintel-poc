import uuid
from datetime import date

from fastapi import APIRouter, HTTPException

from api.deps import DbSession
from models.medical import MedicalRecord
from repositories import profile_repo
from schemas.profile import (
    ProfileCreate,
    ProfileListResponse,
    ProfileOnboardingCreate,
    ProfileOnboardingUpdate,
    ProfileRead,
    ProfileUpdate,
)

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
    if primary_diagnosis is not None and primary_diagnosis.strip():
        cond_text = ", ".join([c.strip() for c in (chronic_conditions or []) if c.strip()])
        allg_text = ", ".join([a.strip() for a in (allergies or []) if a.strip()])
        meds_text = ", ".join([m.strip() for m in (current_medications or []) if m.strip()])
        extra = []
        if cond_text:
            extra.append(f"Benh nen: {cond_text}")
        if allg_text:
            extra.append(f"Di ung: {allg_text}")
        if meds_text:
            extra.append(f"Thuoc hien tai: {meds_text}")
        if medical_notes and medical_notes.strip():
            extra.append(f"Ghi chu: {medical_notes.strip()}")
        notes = " | ".join(extra) if extra else None
        record = MedicalRecord(
            profile_id=profile_id,
            disease_name=primary_diagnosis.strip(),
            treatment_start_date=date.today(),
            treatment_status=(treatment_status or "active").strip(),
            treatment_type="onboarding",
            notes=notes,
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


@router.get("/", response_model=ProfileListResponse)
def list_profiles(db: DbSession):
    items = profile_repo.list_all(db)
    return ProfileListResponse(items=[_to_profile_read(p) for p in items])


@router.post("/", response_model=ProfileRead)
def create_profile(body: ProfileCreate, db: DbSession):
    profile = profile_repo.create(
        db,
        full_name=body.full_name,
        role=body.role,
        date_of_birth=body.date_of_birth,
        email=body.email,
        phone_number=body.phone_number,
        emergency_contact=body.emergency_contact,
    )
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


@router.patch("/{profile_id}", response_model=ProfileRead)
def update_profile(profile_id: str, body: ProfileUpdate, db: DbSession):
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


@router.get("/phone/{phone}", response_model=ProfileRead)
def get_profile_by_phone(phone: str, db: DbSession):
    p = profile_repo.get_by_phone(db, phone)
    if p is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    return _to_profile_read(p)


@router.delete("/{profile_id}")
def delete_profile(profile_id: str, db: DbSession):
    try:
        pid = uuid.UUID(profile_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid UUID") from exc
    profile = profile_repo.get_by_id(db, pid)
    if profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    profile_repo.delete(db, profile)
    return {"ok": True, "profile_id": profile_id}
