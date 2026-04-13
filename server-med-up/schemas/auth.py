from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class PhoneRegisterRequest(BaseModel):
    full_name: str
    phone_number: str
    password: str
    role: str = "patient"


class PhoneLoginRequest(BaseModel):
    phone_number: str
    password: str


class SessionTokenRequest(BaseModel):
    session_token: str


class SessionUser(BaseModel):
    profile_id: str
    full_name: str
    role: str
    phone_number: str | None = None


class SessionAuthResponse(BaseModel):
    session_token: str
    token_type: str = "session"
    expires_at: datetime
    user: SessionUser
