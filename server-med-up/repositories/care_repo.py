from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from models.care import CareGroup, CareGroupMember, CareGroupPatient
from models.profile import Profile


class CareRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_groups_for_member(self, profile_id: uuid.UUID) -> list[CareGroup]:
        """Gets all care groups where the profile is a caregiver/member."""
        stmt = (
            select(CareGroup)
            .join(CareGroupMember, CareGroup.id == CareGroupMember.group_id)
            .where(CareGroupMember.profile_id == profile_id)
        )
        return list(self.db.scalars(stmt))

    def get_patients_for_group(self, group_id: uuid.UUID) -> list[Profile]:
        """Gets all patients belonging to a specific care group."""
        stmt = (
            select(Profile)
            .join(CareGroupPatient, Profile.id == CareGroupPatient.patient_id)
            .where(CareGroupPatient.group_id == group_id)
        )
        return list(self.db.scalars(stmt))

    def get_care_group_patient(self, group_id: uuid.UUID, patient_id: uuid.UUID) -> CareGroupPatient | None:
        return self.db.scalar(
            select(CareGroupPatient)
            .where(CareGroupPatient.group_id == group_id)
            .where(CareGroupPatient.patient_id == patient_id)
        )

    def get_members_for_patient(self, patient_profile_id: uuid.UUID) -> list[Profile]:
        """
        Gets all group members across all care groups that this patient is part of.
        Useful for notifying involved caregivers.
        """
        stmt = (
            select(Profile)
            .join(CareGroupMember, Profile.id == CareGroupMember.profile_id)
            .join(CareGroupPatient, CareGroupMember.group_id == CareGroupPatient.group_id)
            .where(CareGroupPatient.patient_id == patient_profile_id)
            # Make sure we check consent if it's strictly required
            .where(CareGroupPatient.consent_status == "granted")
        )
        return list(self.db.scalars(stmt))
