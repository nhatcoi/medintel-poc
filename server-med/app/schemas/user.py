from pydantic import BaseModel, EmailStr


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: str | None = None


class DeviceSetup(BaseModel):
    full_name: str
    date_of_birth: str | None = None
    gender: str | None = None
    medical_notes: str | None = None


class SyncRequest(BaseModel):
    email: EmailStr


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserRead(BaseModel):
    id: str
    email: str | None = None
    full_name: str | None = None
    role: str = "patient"

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserRead
