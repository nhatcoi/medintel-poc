"""Dữ liệu tham chiếu / demo khi khởi động (sau create_all)."""

from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.medical import DiseaseCategory
from app.models.profile import Profile


def seed_reference_data(session: Session) -> None:
    """Seed DiseaseCategory mặc định + Profile demo nếu chưa tồn tại."""
    try:
        if not session.scalars(select(DiseaseCategory).limit(1)).first():
            session.add(
                DiseaseCategory(
                    category_name="Chưa phân loại",
                    description="Mặc định hệ thống / OCR",
                )
            )
            session.commit()
    except Exception as e:
        print(f"Could not seed disease category: {e}")
        session.rollback()

    try:
        raw_uid = str(settings.default_prescription_user_id).strip()
        if not raw_uid:
            raise ValueError("default_prescription_user_id trống")
        uid = uuid.UUID(raw_uid)
        if not session.get(Profile, uid):
            session.add(
                Profile(
                    id=uid,
                    full_name="Demo User",
                    role="patient",
                    email="demo@medintel.local",
                )
            )
            session.commit()
            print(f"Created demo profile: {uid}")
    except Exception as e:
        print(f"Could not create demo profile: {e}")
        session.rollback()
