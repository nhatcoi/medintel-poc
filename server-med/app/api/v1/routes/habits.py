"""CRUD thói quen sức khỏe + logs."""

from __future__ import annotations

import uuid
from datetime import date, time as dt_time

from fastapi import APIRouter, HTTPException, Query
from sqlalchemy import select

from app.api.deps import DbSession
from app.models.habits import HabitCategory, HabitLog, HabitReminder, HealthHabit
from app.schemas.habits import (
    HabitCategoryCreate,
    HabitCategoryRead,
    HabitCreate,
    HabitListResponse,
    HabitLogCreate,
    HabitLogListResponse,
    HabitLogRead,
    HabitRead,
    HabitReminderRead,
    HabitUpdate,
)

router = APIRouter()


def _parse_hhmm(s: str) -> dt_time:
    parts = s.strip().replace(".", ":").split(":")
    return dt_time(hour=int(parts[0]), minute=int(parts[1]) if len(parts) > 1 else 0)


# ── HabitCategory ────────────────────────────────────────────────────────


@router.get("/categories", response_model=list[HabitCategoryRead])
def list_habit_categories(db: DbSession):
    rows = db.scalars(select(HabitCategory).order_by(HabitCategory.category_name)).all()
    return [HabitCategoryRead(category_id=r.id, category_name=r.category_name, description=r.description) for r in rows]


@router.post("/categories", response_model=HabitCategoryRead, status_code=201)
def create_habit_category(body: HabitCategoryCreate, db: DbSession):
    cat = HabitCategory(category_name=body.category_name, description=body.description)
    db.add(cat)
    db.commit()
    db.refresh(cat)
    return HabitCategoryRead(category_id=cat.id, category_name=cat.category_name, description=cat.description)


# ── HealthHabit ──────────────────────────────────────────────────────────


def _habit_to_read(h: HealthHabit) -> HabitRead:
    return HabitRead(
        habit_id=h.id,
        profile_id=h.profile_id,
        habit_name=h.habit_name,
        category_id=h.category_id,
        description=h.description,
        target_time=h.target_time,
        status=h.status,
        reminders=[
            HabitReminderRead(
                reminder_id=r.id,
                reminder_time=r.reminder_time,
                repeat_frequency=r.repeat_frequency,
                repeat_interval=r.repeat_interval,
                repeat_days=r.repeat_days,
                first_reminder_date=r.first_reminder_date,
                end_date=r.end_date,
                status=r.status,
            )
            for r in h.reminders
        ],
    )


def _sync_reminders(db: DbSession, habit: HealthHabit, slots: list) -> None:
    for old in list(habit.reminders):
        db.delete(old)
    db.flush()
    for slot in slots:
        db.add(
            HabitReminder(
                habit_id=habit.id,
                reminder_time=_parse_hhmm(slot.reminder_time),
                repeat_frequency=slot.repeat_frequency,
                repeat_interval=slot.repeat_interval,
                repeat_days=slot.repeat_days,
                first_reminder_date=slot.first_reminder_date or date.today(),
                end_date=slot.end_date,
            )
        )


@router.get("", response_model=HabitListResponse)
def list_habits(db: DbSession, profile_id: uuid.UUID = Query(...)):
    rows = db.scalars(
        select(HealthHabit)
        .where(HealthHabit.profile_id == profile_id)
        .order_by(HealthHabit.created_at.desc())
    ).all()
    return HabitListResponse(profile_id=profile_id, items=[_habit_to_read(h) for h in rows])


@router.post("", response_model=HabitRead, status_code=201)
def create_habit(body: HabitCreate, db: DbSession):
    target = _parse_hhmm(body.target_time) if body.target_time else None
    habit = HealthHabit(
        profile_id=body.profile_id,
        habit_name=body.habit_name,
        category_id=body.category_id,
        description=body.description,
        target_time=target,
        status=body.status,
    )
    db.add(habit)
    db.flush()
    _sync_reminders(db, habit, body.reminders)
    db.commit()
    db.refresh(habit)
    return _habit_to_read(habit)


@router.get("/{habit_id}", response_model=HabitRead)
def get_habit(habit_id: uuid.UUID, db: DbSession):
    habit = db.get(HealthHabit, habit_id)
    if not habit:
        raise HTTPException(404, "Không tìm thấy thói quen")
    return _habit_to_read(habit)


@router.patch("/{habit_id}", response_model=HabitRead)
def update_habit(habit_id: uuid.UUID, body: HabitUpdate, db: DbSession):
    habit = db.get(HealthHabit, habit_id)
    if not habit:
        raise HTTPException(404, "Không tìm thấy thói quen")
    data = body.model_dump(exclude_unset=True)
    reminders = data.pop("reminders", None)
    if "target_time" in data:
        data["target_time"] = _parse_hhmm(data["target_time"]) if data["target_time"] else None
    for k, v in data.items():
        setattr(habit, k, v)
    if reminders is not None:
        _sync_reminders(db, habit, body.reminders)  # type: ignore[arg-type]
    db.commit()
    db.refresh(habit)
    return _habit_to_read(habit)


@router.delete("/{habit_id}", status_code=204)
def delete_habit(habit_id: uuid.UUID, db: DbSession):
    habit = db.get(HealthHabit, habit_id)
    if not habit:
        raise HTTPException(404, "Không tìm thấy thói quen")
    db.delete(habit)
    db.commit()


# ── HabitLog ─────────────────────────────────────────────────────────────


@router.get("/{habit_id}/logs", response_model=HabitLogListResponse)
def list_habit_logs(habit_id: uuid.UUID, db: DbSession):
    rows = db.scalars(
        select(HabitLog)
        .where(HabitLog.habit_id == habit_id)
        .order_by(HabitLog.scheduled_datetime.desc())
    ).all()
    items = [
        HabitLogRead(
            log_id=r.id,
            habit_id=r.habit_id,
            profile_id=r.profile_id,
            scheduled_datetime=r.scheduled_datetime,
            actual_datetime=r.actual_datetime,
            status=r.status,
            notes=r.notes,
            created_at=r.created_at,
        )
        for r in rows
    ]
    return HabitLogListResponse(habit_id=habit_id, items=items)


@router.post("/{habit_id}/logs", response_model=HabitLogRead, status_code=201)
def create_habit_log(habit_id: uuid.UUID, body: HabitLogCreate, db: DbSession):
    habit = db.get(HealthHabit, habit_id)
    if not habit:
        raise HTTPException(404, "Không tìm thấy thói quen")
    log = HabitLog(
        habit_id=habit_id,
        profile_id=body.profile_id,
        scheduled_datetime=body.scheduled_datetime,
        actual_datetime=body.actual_datetime,
        status=body.status,
        notes=body.notes,
    )
    db.add(log)
    db.commit()
    db.refresh(log)
    return HabitLogRead(
        log_id=log.id,
        habit_id=log.habit_id,
        profile_id=log.profile_id,
        scheduled_datetime=log.scheduled_datetime,
        actual_datetime=log.actual_datetime,
        status=log.status,
        notes=log.notes,
        created_at=log.created_at,
    )
