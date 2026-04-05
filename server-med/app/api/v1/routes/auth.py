from fastapi import APIRouter, HTTPException, status

from app.api.deps import DbSession
from app.models.user import User
from app.repositories.user_repository import create_user, get_by_email, get_by_id
from app.schemas.user import DeviceSetup, SyncRequest, TokenResponse, UserRead
from app.services.auth_service import create_access_token, hash_password

router = APIRouter()


@router.post("/device-setup", response_model=TokenResponse)
def device_setup(body: DeviceSetup, db: DbSession):
    """First-time device setup: create user without password."""
    import uuid
    user = User(
        email=f"{uuid.uuid4().hex[:8]}@device.local",
        hashed_password=hash_password(uuid.uuid4().hex),
        full_name=body.full_name,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    token = create_access_token(str(user.id))
    return TokenResponse(
        access_token=token,
        user=UserRead(id=str(user.id), full_name=user.full_name, role=user.role),
    )


@router.post("/sync-email", response_model=UserRead)
def sync_email(body: SyncRequest, db: DbSession):
    """Link an email to existing device-local user for sync."""
    # For now: just check if email exists
    existing = get_by_email(db, body.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email da duoc su dung boi tai khoan khac",
        )
    # TODO: update user email and enable cloud sync
    return UserRead(id="", email=body.email, full_name=None, role="patient")
