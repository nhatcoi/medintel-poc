import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.profile import Profile


def get_by_id(db: Session, profile_id: uuid.UUID) -> Profile | None:
    return db.get(Profile, profile_id)


def get_by_email(db: Session, email: str) -> Profile | None:
    return db.scalars(select(Profile).where(Profile.email == email)).first()


def create_profile(
    db: Session,
    *,
    full_name: str,
    email: str | None = None,
    role: str = "patient",
) -> Profile:
    p = Profile(full_name=full_name, email=email, role=role)
    db.add(p)
    db.commit()
    db.refresh(p)
    return p
