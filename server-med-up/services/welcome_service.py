"""Welcome hints + suggested questions for the chat UI."""

from __future__ import annotations

import uuid

from sqlalchemy.orm import Session

from repositories import medication_repo


async def build_welcome_hints(db: Session, profile_id: uuid.UUID) -> tuple[list[str], str]:
    meds = medication_repo.get_medications_by_profile(db, profile_id)
    if not meds:
        return ["Chào bạn! Hãy thêm thuốc để MedIntel hỗ trợ bạn tốt hơn."], "template"

    med_names = [m.medication_name for m in meds[:3]]
    hints = [
        f"Chào bạn! Hôm nay bạn đang uống {', '.join(med_names)}.",
        "Hãy hỏi mình bất cứ điều gì về thuốc hoặc sức khỏe nhé!",
    ]
    return hints, "template"


async def build_suggested_questions(db: Session, profile_id: uuid.UUID) -> tuple[list[str], str]:
    meds = medication_repo.get_medications_by_profile(db, profile_id)
    questions = [
        "Hôm nay tôi cần uống thuốc gì?",
        "Thuốc này có tác dụng phụ gì?",
    ]
    if meds:
        questions.insert(0, f"{meds[0].medication_name} uống trước hay sau ăn?")
    return questions, "template"
