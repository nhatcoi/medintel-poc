from fastapi import APIRouter, HTTPException, status

from app.api.deps import DbSession
from app.repositories.user_repository import create_user, get_by_email
from app.schemas.user import UserCreate, UserRead
from app.services.auth_service import hash_password

router = APIRouter()


@router.post("/register", response_model=UserRead)
def register(body: UserCreate, db: DbSession):
    if get_by_email(db, body.email):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email đã tồn tại")
    user = create_user(
        db,
        email=body.email,
        hashed_password=hash_password(body.password),
        full_name=body.full_name,
    )
    return UserRead(id=str(user.id), email=user.email, full_name=user.full_name, role=user.role)
