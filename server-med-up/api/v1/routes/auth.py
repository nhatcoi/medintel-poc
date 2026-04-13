from fastapi import APIRouter, HTTPException, Request

from api.deps import DbSession
from schemas.auth import (
    PhoneLoginRequest,
    PhoneRegisterRequest,
    SessionAuthResponse,
    SessionTokenRequest,
    SessionUser,
)
from schemas.profile import ProfileCreate, TokenResponse
from services.auth_service import (
    get_active_session,
    login_with_phone_password,
    logout_session,
    register_device,
    register_with_phone_password,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse)
def register(body: ProfileCreate, db: DbSession):
    profile, token = register_device(
        db, full_name=body.full_name, role=body.role, platform=None
    )
    return TokenResponse(access_token=token, profile_id=str(profile.id))


@router.post("/register-phone", response_model=SessionAuthResponse)
def register_phone(body: PhoneRegisterRequest, request: Request, db: DbSession):
    try:
        profile, session = register_with_phone_password(
            db,
            full_name=body.full_name,
            phone_number=body.phone_number,
            password=body.password,
            role=body.role,
            ip_address=request.client.host if request.client else None,
            user_agent=request.headers.get("user-agent"),
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return SessionAuthResponse(
        session_token=session.session_token,
        expires_at=session.expires_at,
        user=SessionUser(
            profile_id=str(profile.id),
            full_name=profile.full_name,
            role=profile.role,
            phone_number=profile.phone_number,
        ),
    )


@router.post("/login-phone", response_model=SessionAuthResponse)
def login_phone(body: PhoneLoginRequest, request: Request, db: DbSession):
    try:
        profile, session = login_with_phone_password(
            db,
            phone_number=body.phone_number,
            password=body.password,
            ip_address=request.client.host if request.client else None,
            user_agent=request.headers.get("user-agent"),
        )
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc)) from exc
    return SessionAuthResponse(
        session_token=session.session_token,
        expires_at=session.expires_at,
        user=SessionUser(
            profile_id=str(profile.id),
            full_name=profile.full_name,
            role=profile.role,
            phone_number=profile.phone_number,
        ),
    )


@router.post("/logout-phone")
def logout_phone(body: SessionTokenRequest, db: DbSession):
    ok = logout_session(db, body.session_token)
    return {"ok": ok}


@router.post("/session/me", response_model=SessionUser)
def session_me(body: SessionTokenRequest, db: DbSession):
    sess = get_active_session(db, body.session_token)
    if sess is None:
        raise HTTPException(status_code=401, detail="invalid or expired session")
    from models.profile import Profile
    p = db.get(Profile, sess.profile_id)
    if p is None:
        raise HTTPException(status_code=404, detail="profile not found")
    return SessionUser(
        profile_id=str(p.id),
        full_name=p.full_name,
        role=p.role,
        phone_number=p.phone_number,
    )
