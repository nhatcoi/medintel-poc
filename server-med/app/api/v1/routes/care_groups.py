"""CRUD nhóm chăm sóc + liên kết caregiver-patient."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, HTTPException, Query
from sqlalchemy import select

from app.api.deps import DbSession
from app.models.care import CaregiverPatientLink, CareGroup, CareGroupMember, CareGroupPatient
from app.models.mixins import utc_now
from app.schemas.care import (
    CareGroupCreate,
    CareGroupMemberAdd,
    CareGroupMemberRead,
    CareGroupPatientAdd,
    CareGroupPatientRead,
    CareGroupRead,
    CareGroupUpdate,
    CareLinkCreate,
    CareLinkRead,
    CareLinkUpdate,
)

router = APIRouter()


# ── CaregiverPatientLink ─────────────────────────────────────────────────


@router.get("/links", response_model=list[CareLinkRead])
def list_links(db: DbSession, profile_id: uuid.UUID = Query(..., description="patient hoặc caregiver")):
    rows = db.scalars(
        select(CaregiverPatientLink).where(
            (CaregiverPatientLink.patient_id == profile_id)
            | (CaregiverPatientLink.caregiver_id == profile_id)
        )
    ).all()
    return [
        CareLinkRead(
            link_id=r.id,
            patient_id=r.patient_id,
            caregiver_id=r.caregiver_id,
            relationship=r.relationship,
            permission_level=r.permission_level,
            status=r.status,
            requested_at=r.requested_at,
            responded_at=r.responded_at,
        )
        for r in rows
    ]


@router.post("/links", response_model=CareLinkRead, status_code=201)
def create_link(body: CareLinkCreate, db: DbSession):
    link = CaregiverPatientLink(
        patient_id=body.patient_id,
        caregiver_id=body.caregiver_id,
        relationship=body.relationship,
        permission_level=body.permission_level,
        status="pending",
        requested_at=utc_now(),
    )
    db.add(link)
    db.commit()
    db.refresh(link)
    return CareLinkRead(
        link_id=link.id,
        patient_id=link.patient_id,
        caregiver_id=link.caregiver_id,
        relationship=link.relationship,
        permission_level=link.permission_level,
        status=link.status,
        requested_at=link.requested_at,
        responded_at=link.responded_at,
    )


@router.patch("/links/{link_id}", response_model=CareLinkRead)
def update_link(link_id: uuid.UUID, body: CareLinkUpdate, db: DbSession):
    link = db.get(CaregiverPatientLink, link_id)
    if not link:
        raise HTTPException(404, "Không tìm thấy liên kết")
    data = body.model_dump(exclude_unset=True)
    if "status" in data and data["status"] in ("accepted", "rejected"):
        data["responded_at"] = utc_now()
    for k, v in data.items():
        setattr(link, k, v)
    db.commit()
    db.refresh(link)
    return CareLinkRead(
        link_id=link.id,
        patient_id=link.patient_id,
        caregiver_id=link.caregiver_id,
        relationship=link.relationship,
        permission_level=link.permission_level,
        status=link.status,
        requested_at=link.requested_at,
        responded_at=link.responded_at,
    )


@router.delete("/links/{link_id}", status_code=204)
def delete_link(link_id: uuid.UUID, db: DbSession):
    link = db.get(CaregiverPatientLink, link_id)
    if not link:
        raise HTTPException(404, "Không tìm thấy liên kết")
    db.delete(link)
    db.commit()


# ── CareGroup ────────────────────────────────────────────────────────────


@router.get("/groups", response_model=list[CareGroupRead])
def list_groups(db: DbSession, profile_id: uuid.UUID = Query(...)):
    member_groups = db.scalars(
        select(CareGroupMember.group_id).where(CareGroupMember.profile_id == profile_id)
    ).all()
    created_groups = db.scalars(
        select(CareGroup.id).where(CareGroup.created_by_profile_id == profile_id)
    ).all()
    all_ids = set(member_groups) | set(created_groups)
    if not all_ids:
        return []

    groups = db.scalars(select(CareGroup).where(CareGroup.id.in_(all_ids))).all()
    result = []
    for g in groups:
        members = db.scalars(select(CareGroupMember).where(CareGroupMember.group_id == g.id)).all()
        patients = db.scalars(select(CareGroupPatient).where(CareGroupPatient.group_id == g.id)).all()
        result.append(
            CareGroupRead(
                group_id=g.id,
                group_name=g.group_name,
                description=g.description,
                created_by_profile_id=g.created_by_profile_id,
                members=[
                    CareGroupMemberRead(
                        member_id=m.id, group_id=m.group_id, profile_id=m.profile_id,
                        role=m.role, joined_at=m.joined_at,
                    )
                    for m in members
                ],
                patients=[
                    CareGroupPatientRead(
                        id=p.id, group_id=p.group_id, patient_id=p.patient_id,
                        added_by_profile_id=p.added_by_profile_id, added_at=p.added_at,
                    )
                    for p in patients
                ],
            )
        )
    return result


@router.post("/groups", response_model=CareGroupRead, status_code=201)
def create_group(body: CareGroupCreate, db: DbSession):
    group = CareGroup(
        group_name=body.group_name,
        description=body.description,
        created_by_profile_id=body.created_by_profile_id,
    )
    db.add(group)
    db.flush()
    db.add(CareGroupMember(group_id=group.id, profile_id=body.created_by_profile_id, role="admin"))
    db.commit()
    db.refresh(group)
    return CareGroupRead(
        group_id=group.id,
        group_name=group.group_name,
        description=group.description,
        created_by_profile_id=group.created_by_profile_id,
        members=[],
        patients=[],
    )


@router.patch("/groups/{group_id}", response_model=CareGroupRead)
def update_group(group_id: uuid.UUID, body: CareGroupUpdate, db: DbSession):
    group = db.get(CareGroup, group_id)
    if not group:
        raise HTTPException(404, "Không tìm thấy nhóm")
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(group, k, v)
    db.commit()
    db.refresh(group)
    return CareGroupRead(
        group_id=group.id, group_name=group.group_name,
        description=group.description, created_by_profile_id=group.created_by_profile_id,
    )


@router.delete("/groups/{group_id}", status_code=204)
def delete_group(group_id: uuid.UUID, db: DbSession):
    group = db.get(CareGroup, group_id)
    if not group:
        raise HTTPException(404, "Không tìm thấy nhóm")
    db.execute(CareGroupMember.__table__.delete().where(CareGroupMember.group_id == group_id))
    db.execute(CareGroupPatient.__table__.delete().where(CareGroupPatient.group_id == group_id))
    db.delete(group)
    db.commit()


# ── Group members / patients ─────────────────────────────────────────────


@router.post("/groups/{group_id}/members", response_model=CareGroupMemberRead, status_code=201)
def add_member(group_id: uuid.UUID, body: CareGroupMemberAdd, db: DbSession):
    if not db.get(CareGroup, group_id):
        raise HTTPException(404, "Không tìm thấy nhóm")
    m = CareGroupMember(group_id=group_id, profile_id=body.profile_id, role=body.role)
    db.add(m)
    db.commit()
    db.refresh(m)
    return CareGroupMemberRead(
        member_id=m.id, group_id=m.group_id, profile_id=m.profile_id,
        role=m.role, joined_at=m.joined_at,
    )


@router.delete("/groups/{group_id}/members/{member_id}", status_code=204)
def remove_member(group_id: uuid.UUID, member_id: uuid.UUID, db: DbSession):
    m = db.get(CareGroupMember, member_id)
    if not m or m.group_id != group_id:
        raise HTTPException(404, "Không tìm thấy thành viên")
    db.delete(m)
    db.commit()


@router.post("/groups/{group_id}/patients", response_model=CareGroupPatientRead, status_code=201)
def add_patient(group_id: uuid.UUID, body: CareGroupPatientAdd, db: DbSession):
    if not db.get(CareGroup, group_id):
        raise HTTPException(404, "Không tìm thấy nhóm")
    p = CareGroupPatient(
        group_id=group_id, patient_id=body.patient_id,
        added_by_profile_id=body.added_by_profile_id,
    )
    db.add(p)
    db.commit()
    db.refresh(p)
    return CareGroupPatientRead(
        id=p.id, group_id=p.group_id, patient_id=p.patient_id,
        added_by_profile_id=p.added_by_profile_id, added_at=p.added_at,
    )


@router.delete("/groups/{group_id}/patients/{patient_entry_id}", status_code=204)
def remove_patient(group_id: uuid.UUID, patient_entry_id: uuid.UUID, db: DbSession):
    p = db.get(CareGroupPatient, patient_entry_id)
    if not p or p.group_id != group_id:
        raise HTTPException(404, "Không tìm thấy bệnh nhân trong nhóm")
    db.delete(p)
    db.commit()
