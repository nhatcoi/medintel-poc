import uuid

from fastapi import APIRouter, HTTPException, status

from app.api.deps import DbSession
from app.models.profile import Profile
from app.services.patient_agent_context_service import refresh_patient_agent_context_best_effort
from app.repositories.profile_repository import get_by_email
from app.schemas.user import DeviceSetup, SyncRequest, TokenResponse, UserRead
from app.services.auth_service import create_access_token

router = APIRouter()


@router.post("/device-setup", response_model=TokenResponse)
def device_setup(body: DeviceSetup, db: DbSession):
    """Thiết lập thiết bị: tạo profile và đồng bộ database (không mật khẩu IAM)."""
    profile = Profile(
        full_name=body.full_name,
        role="patient",
        email=f"{uuid.uuid4().hex[:8]}@device.local",
    )
    db.add(profile)
    db.commit()
    db.refresh(profile)
    refresh_patient_agent_context_best_effort(db, profile.id)
    token = create_access_token(str(profile.id))
    return TokenResponse(
        access_token=token,
        user=UserRead(id=str(profile.id), full_name=profile.full_name, role=profile.role),
    )


@router.post("/sync-email", response_model=UserRead)
def sync_email(body: SyncRequest, db: DbSession):
    """Gắn email cho profile — kiểm tra trùng (stub)."""
    existing = get_by_email(db, body.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email da duoc su dung boi tai khoan khac",
        )
    return UserRead(id="", email=body.email, full_name=None, role="patient")
