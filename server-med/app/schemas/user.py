from pydantic import BaseModel, EmailStr


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: str | None = None


class UserRead(BaseModel):
    id: str
    email: EmailStr
    full_name: str | None
    role: str

    model_config = {"from_attributes": True}
