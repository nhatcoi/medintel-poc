from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from models.profile import Profile


def list_all(db: Session) -> list[Profile]:
    return list(db.scalars(select(Profile).order_by(Profile.created_at.desc())).all())


def get_by_id(db: Session, profile_id: uuid.UUID) -> Profile | None:
    return db.get(Profile, profile_id)


def get_by_email(db: Session, email: str) -> Profile | None:
    return db.scalars(select(Profile).where(Profile.email == email)).first()


def get_by_phone(db: Session, phone: str) -> Profile | None:
    return db.scalars(select(Profile).where(Profile.phone_number == phone)).first()


def create(db: Session, *, full_name: str, role: str = "patient", **kwargs) -> Profile:
    p = Profile(full_name=full_name, role=role, **kwargs)
    db.add(p)
    db.commit()
    db.refresh(p)
    return p


def update(db: Session, profile: Profile, **kwargs) -> Profile:
    for key, value in kwargs.items():
        if value is None:
            continue
        if hasattr(profile, key):
            setattr(profile, key, value)
    db.commit()
    db.refresh(profile)
    return profile


def delete(db: Session, profile: Profile) -> None:
    db.delete(profile)
    db.commit()
