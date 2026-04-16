import uuid

from fastapi import APIRouter, HTTPException, Query
from sqlalchemy import select

from api.deps import DbSession
from models.care import CareGroup, CareGroupMember, CareGroupPatient, CaregiverPatientLink
from schemas.care import (
    CareGroupCreate,
    CareGroupMemberCreate,
    CareGroupMemberRead,
    CareGroupMemberUpdate,
    CareGroupPatientCreate,
    CareGroupPatientRead,
    CareGroupRead,
    CareGroupUpdate,
    CaregiverPatientLinkCreate,
    CaregiverPatientLinkRead,
    CaregiverPatientLinkUpdate,
)

router = APIRouter(prefix="/care", tags=["care"])


def _uuid(raw: str, detail: str = "Invalid UUID") -> uuid.UUID:
    try:
        return uuid.UUID(raw.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=detail) from exc


@router.get("/groups", response_model=list[CareGroupRead])
def list_groups(db: DbSession, created_by_profile_id: str | None = Query(None)):
    stmt = select(CareGroup).order_by(CareGroup.created_at.desc())
    if created_by_profile_id:
        stmt = stmt.where(CareGroup.created_by_profile_id == _uuid(created_by_profile_id))
    rows = db.scalars(stmt).all()
    return [
        CareGroupRead(
            group_id=str(r.id),
            group_name=r.group_name,
            description=r.description,
            created_by_profile_id=str(r.created_by_profile_id),
        )
        for r in rows
    ]


@router.post("/groups", response_model=CareGroupRead)
def create_group(body: CareGroupCreate, db: DbSession):
    row = CareGroup(
        group_name=body.group_name,
        description=body.description,
        created_by_profile_id=_uuid(body.created_by_profile_id, "Invalid created_by_profile_id"),
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return CareGroupRead(
        group_id=str(row.id),
        group_name=row.group_name,
        description=row.description,
        created_by_profile_id=str(row.created_by_profile_id),
    )


@router.patch("/groups/{group_id}", response_model=CareGroupRead)
def update_group(group_id: str, body: CareGroupUpdate, db: DbSession):
    row = db.get(CareGroup, _uuid(group_id, "Invalid group_id"))
    if row is None:
        raise HTTPException(status_code=404, detail="Care group not found")
    if body.group_name is not None:
        row.group_name = body.group_name
    if body.description is not None:
        row.description = body.description
    db.commit()
    db.refresh(row)
    return CareGroupRead(
        group_id=str(row.id),
        group_name=row.group_name,
        description=row.description,
        created_by_profile_id=str(row.created_by_profile_id),
    )


@router.delete("/groups/{group_id}")
def delete_group(group_id: str, db: DbSession):
    row = db.get(CareGroup, _uuid(group_id, "Invalid group_id"))
    if row is None:
        raise HTTPException(status_code=404, detail="Care group not found")
    db.delete(row)
    db.commit()
    return {"ok": True, "group_id": group_id}


@router.get("/group-members", response_model=list[CareGroupMemberRead])
def list_group_members(db: DbSession, group_id: str | None = Query(None)):
    stmt = select(CareGroupMember).order_by(CareGroupMember.joined_at.desc())
    if group_id:
        stmt = stmt.where(CareGroupMember.group_id == _uuid(group_id, "Invalid group_id"))
    rows = db.scalars(stmt).all()
    return [
        CareGroupMemberRead(
            member_id=str(r.id),
            group_id=str(r.group_id),
            profile_id=str(r.profile_id),
            role=r.role,
            joined_at=r.joined_at,
        )
        for r in rows
    ]


@router.post("/group-members", response_model=CareGroupMemberRead)
def create_group_member(body: CareGroupMemberCreate, db: DbSession):
    row = CareGroupMember(
        group_id=_uuid(body.group_id, "Invalid group_id"),
        profile_id=_uuid(body.profile_id, "Invalid profile_id"),
        role=body.role,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return CareGroupMemberRead(
        member_id=str(row.id),
        group_id=str(row.group_id),
        profile_id=str(row.profile_id),
        role=row.role,
        joined_at=row.joined_at,
    )


@router.patch("/group-members/{member_id}", response_model=CareGroupMemberRead)
def update_group_member(member_id: str, body: CareGroupMemberUpdate, db: DbSession):
    row = db.get(CareGroupMember, _uuid(member_id, "Invalid member_id"))
    if row is None:
        raise HTTPException(status_code=404, detail="Care group member not found")
    if body.role is not None:
        row.role = body.role
    db.commit()
    db.refresh(row)
    return CareGroupMemberRead(
        member_id=str(row.id),
        group_id=str(row.group_id),
        profile_id=str(row.profile_id),
        role=row.role,
        joined_at=row.joined_at,
    )


@router.delete("/group-members/{member_id}")
def delete_group_member(member_id: str, db: DbSession):
    row = db.get(CareGroupMember, _uuid(member_id, "Invalid member_id"))
    if row is None:
        raise HTTPException(status_code=404, detail="Care group member not found")
    db.delete(row)
    db.commit()
    return {"ok": True, "member_id": member_id}


@router.get("/group-patients", response_model=list[CareGroupPatientRead])
def list_group_patients(db: DbSession, group_id: str | None = Query(None)):
    stmt = select(CareGroupPatient).order_by(CareGroupPatient.added_at.desc())
    if group_id:
        stmt = stmt.where(CareGroupPatient.group_id == _uuid(group_id, "Invalid group_id"))
    rows = db.scalars(stmt).all()
    return [
        CareGroupPatientRead(
            id=str(r.id),
            group_id=str(r.group_id),
            patient_id=str(r.patient_id),
            added_by_profile_id=str(r.added_by_profile_id),
            added_at=r.added_at,
            consent_status=r.consent_status,
        )
        for r in rows
    ]


@router.post("/group-patients", response_model=CareGroupPatientRead)
def create_group_patient(body: CareGroupPatientCreate, db: DbSession):
    row = CareGroupPatient(
        group_id=_uuid(body.group_id, "Invalid group_id"),
        patient_id=_uuid(body.patient_id, "Invalid patient_id"),
        added_by_profile_id=_uuid(body.added_by_profile_id, "Invalid added_by_profile_id"),
        consent_status=body.consent_status,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return CareGroupPatientRead(
        id=str(row.id),
        group_id=str(row.group_id),
        patient_id=str(row.patient_id),
        added_by_profile_id=str(row.added_by_profile_id),
        added_at=row.added_at,
        consent_status=row.consent_status,
    )


@router.delete("/group-patients/{item_id}")
def delete_group_patient(item_id: str, db: DbSession):
    row = db.get(CareGroupPatient, _uuid(item_id, "Invalid item_id"))
    if row is None:
        raise HTTPException(status_code=404, detail="Care group patient not found")
    db.delete(row)
    db.commit()
    return {"ok": True, "id": item_id}


@router.get("/caregiver-links", response_model=list[CaregiverPatientLinkRead])
def list_caregiver_links(
    db: DbSession,
    patient_id: str | None = Query(None),
    caregiver_id: str | None = Query(None),
):
    stmt = select(CaregiverPatientLink).order_by(CaregiverPatientLink.created_at.desc())
    if patient_id:
        stmt = stmt.where(CaregiverPatientLink.patient_id == _uuid(patient_id, "Invalid patient_id"))
    if caregiver_id:
        stmt = stmt.where(CaregiverPatientLink.caregiver_id == _uuid(caregiver_id, "Invalid caregiver_id"))
    rows = db.scalars(stmt).all()
    return [
        CaregiverPatientLinkRead(
            link_id=str(r.id),
            patient_id=str(r.patient_id),
            caregiver_id=str(r.caregiver_id),
            relationship=r.relationship,
            permission_level=r.permission_level,
            status=r.status,
            requested_at=r.requested_at,
            responded_at=r.responded_at,
        )
        for r in rows
    ]


@router.post("/caregiver-links", response_model=CaregiverPatientLinkRead)
def create_caregiver_link(body: CaregiverPatientLinkCreate, db: DbSession):
    row = CaregiverPatientLink(
        patient_id=_uuid(body.patient_id, "Invalid patient_id"),
        caregiver_id=_uuid(body.caregiver_id, "Invalid caregiver_id"),
        relationship=body.relationship,
        permission_level=body.permission_level,
        status=body.status,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return CaregiverPatientLinkRead(
        link_id=str(row.id),
        patient_id=str(row.patient_id),
        caregiver_id=str(row.caregiver_id),
        relationship=row.relationship,
        permission_level=row.permission_level,
        status=row.status,
        requested_at=row.requested_at,
        responded_at=row.responded_at,
    )


@router.patch("/caregiver-links/{link_id}", response_model=CaregiverPatientLinkRead)
def update_caregiver_link(link_id: str, body: CaregiverPatientLinkUpdate, db: DbSession):
    row = db.get(CaregiverPatientLink, _uuid(link_id, "Invalid link_id"))
    if row is None:
        raise HTTPException(status_code=404, detail="Caregiver link not found")
    for key in ("relationship", "permission_level", "status", "responded_at"):
        value = getattr(body, key)
        if value is not None:
            setattr(row, key, value)
    db.commit()
    db.refresh(row)
    return CaregiverPatientLinkRead(
        link_id=str(row.id),
        patient_id=str(row.patient_id),
        caregiver_id=str(row.caregiver_id),
        relationship=row.relationship,
        permission_level=row.permission_level,
        status=row.status,
        requested_at=row.requested_at,
        responded_at=row.responded_at,
    )


@router.delete("/caregiver-links/{link_id}")
def delete_caregiver_link(link_id: str, db: DbSession):
    row = db.get(CaregiverPatientLink, _uuid(link_id, "Invalid link_id"))
    if row is None:
        raise HTTPException(status_code=404, detail="Caregiver link not found")
    db.delete(row)
    db.commit()
    return {"ok": True, "link_id": link_id}


@router.get("/my-patients")
def list_my_patients(db: DbSession, profile_id: str = Query(..., description="The caregiver profile ID")):
    """
    Returns a list of patients inside groups where this profile_id acts as a member/caregiver.
    """
    from repositories.care_repo import CareRepository
    care_repo = CareRepository(db)
    
    uid = _uuid(profile_id, "Invalid profile_id")
    groups = care_repo.get_groups_for_member(uid)
    
    unique_patients = set()
    patients_list = []
    
    for g in groups:
        patients = care_repo.get_patients_for_group(g.id)
        for p in patients:
            if p.id not in unique_patients:
                unique_patients.add(p.id)
                # Just return raw dict instead of strict BaseModel 
                # in case ProfileRead requires full attrs
                patients_list.append({
                    "id": str(p.id),
                    "full_name": p.full_name,
                    "role": p.role,
                })
    return patients_list

