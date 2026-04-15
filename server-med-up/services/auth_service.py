"""Auth services: device setup (legacy) + phone/password session auth."""

from __future__ import annotations

import secrets
import uuid
from datetime import timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from core.security import create_access_token
from models.auth import AuthCredential, AuthSession
from models.profile import Profile
from models.base import utc_now
from core.security import hash_password, verify_password


def register_device(db: Session, *, full_name: str, role: str = "patient", platform: str | None = None) -> tuple[Profile, str]:
    profile = Profile(full_name=full_name, role=role)
    db.add(profile)
    db.commit()
    db.refresh(profile)

    token = create_access_token({"sub": str(profile.id), "role": role})
    return profile, token


def _new_session_token() -> str:
    return secrets.token_urlsafe(48)


def register_with_phone_password(
    db: Session,
    *,
    full_name: str,
    phone_number: str,
    password: str,
    role: str = "patient",
    ip_address: str | None = None,
    user_agent: str | None = None,
) -> tuple[Profile, AuthSession]:
    phone = phone_number.strip()
    if not phone:
        raise ValueError("phone_number is required")
    if len(password) < 6:
        raise ValueError("password must be at least 6 characters")

    existing = db.scalars(
        select(AuthCredential).where(AuthCredential.phone_number == phone)
    ).first()
    if existing is not None:
        raise ValueError("phone already registered")

    profile = Profile(full_name=full_name.strip() or "User", role=role, phone_number=phone)
    db.add(profile)
    db.flush()

    cred = AuthCredential(
        profile_id=profile.id,
        phone_number=phone,
        password_hash=hash_password(password),
    )
    db.add(cred)

    session = AuthSession(
        profile_id=profile.id,
        session_token=_new_session_token(),
        expires_at=utc_now() + timedelta(days=30),
        ip_address=ip_address,
        user_agent=user_agent,
    )
    db.add(session)
    db.commit()
    db.refresh(profile)
    db.refresh(session)
    return profile, session


def login_with_phone_password(
    db: Session,
    *,
    phone_number: str,
    password: str,
    ip_address: str | None = None,
    user_agent: str | None = None,
) -> tuple[Profile, AuthSession]:
    phone = phone_number.strip()
    cred = db.scalars(
        select(AuthCredential).where(AuthCredential.phone_number == phone)
    ).first()
    if cred is None or not verify_password(password, cred.password_hash):
        raise ValueError("invalid credentials")

    profile = db.get(Profile, cred.profile_id)
    if profile is None:
        raise ValueError("profile not found")

    session = AuthSession(
        profile_id=profile.id,
        session_token=_new_session_token(),
        expires_at=utc_now() + timedelta(days=30),
        ip_address=ip_address,
        user_agent=user_agent,
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return profile, session


def get_active_session(db: Session, session_token: str) -> AuthSession | None:
    token = session_token.strip()
    if not token:
        return None
    session = db.scalars(
        select(AuthSession).where(AuthSession.session_token == token)
    ).first()
    if session is None:
        return None
    if not session.is_active():
        return None
    return session


def logout_session(db: Session, session_token: str) -> bool:
    session = get_active_session(db, session_token)
    if session is None:
        return False
    session.revoked_at = utc_now()
    db.commit()
    return True
