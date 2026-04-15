import uuid

from fastapi import APIRouter, HTTPException, Query
from sqlalchemy import select

from api.deps import DbSession
from models.habits import HabitCategory, HabitLog, HabitReminder, HealthHabit
from schemas.habits import (
    HabitCategoryCreate,
    HabitCategoryRead,
    HabitLogCreate,
    HabitLogRead,
    HabitLogUpdate,
    HabitReminderCreate,
    HabitReminderRead,
    HabitReminderUpdate,
    HealthHabitCreate,
    HealthHabitRead,
    HealthHabitUpdate,
)

router = APIRouter(prefix="/habits", tags=["habits"])


def _uuid(raw: str, detail: str = "Invalid UUID") -> uuid.UUID:
    try:
        return uuid.UUID(raw.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=detail) from exc


@router.get("/categories", response_model=list[HabitCategoryRead])
def list_categories(db: DbSession):
    rows = db.scalars(select(HabitCategory).order_by(HabitCategory.created_at.desc())).all()
    return [HabitCategoryRead(category_id=str(r.id), category_name=r.category_name, description=r.description) for r in rows]


@router.post("/categories", response_model=HabitCategoryRead)
def create_category(body: HabitCategoryCreate, db: DbSession):
    row = HabitCategory(category_name=body.category_name, description=body.description)
    db.add(row)
    db.commit()
    db.refresh(row)
    return HabitCategoryRead(category_id=str(row.id), category_name=row.category_name, description=row.description)


@router.delete("/categories/{category_id}")
def delete_category(category_id: str, db: DbSession):
    row = db.get(HabitCategory, _uuid(category_id, "Invalid category_id"))
    if row is None:
        raise HTTPException(status_code=404, detail="Habit category not found")
    db.delete(row)
    db.commit()
    return {"ok": True, "category_id": category_id}


@router.get("/", response_model=list[HealthHabitRead])
def list_habits(db: DbSession, profile_id: str | None = Query(None)):
    stmt = select(HealthHabit).order_by(HealthHabit.created_at.desc())
    if profile_id:
        stmt = stmt.where(HealthHabit.profile_id == _uuid(profile_id, "Invalid profile_id"))
    rows = db.scalars(stmt).all()
    return [
        HealthHabitRead(
            habit_id=str(r.id),
            profile_id=str(r.profile_id),
            habit_name=r.habit_name,
            category_id=str(r.category_id) if r.category_id else None,
            description=r.description,
            target_time=r.target_time,
            status=r.status,
        )
        for r in rows
    ]


@router.post("/", response_model=HealthHabitRead)
def create_habit(body: HealthHabitCreate, db: DbSession):
    row = HealthHabit(
        profile_id=_uuid(body.profile_id, "Invalid profile_id"),
        habit_name=body.habit_name,
        category_id=_uuid(body.category_id, "Invalid category_id") if body.category_id else None,
        description=body.description,
        target_time=body.target_time,
        status=body.status,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return HealthHabitRead(
        habit_id=str(row.id),
        profile_id=str(row.profile_id),
        habit_name=row.habit_name,
        category_id=str(row.category_id) if row.category_id else None,
        description=row.description,
        target_time=row.target_time,
        status=row.status,
    )


@router.patch("/{habit_id}", response_model=HealthHabitRead)
def update_habit(habit_id: str, body: HealthHabitUpdate, db: DbSession):
    row = db.get(HealthHabit, _uuid(habit_id, "Invalid habit_id"))
    if row is None:
        raise HTTPException(status_code=404, detail="Health habit not found")
    if body.habit_name is not None:
        row.habit_name = body.habit_name
    if body.category_id is not None:
        row.category_id = _uuid(body.category_id, "Invalid category_id")
    if body.description is not None:
        row.description = body.description
    if body.target_time is not None:
        row.target_time = body.target_time
    if body.status is not None:
        row.status = body.status
    db.commit()
    db.refresh(row)
    return HealthHabitRead(
        habit_id=str(row.id),
        profile_id=str(row.profile_id),
        habit_name=row.habit_name,
        category_id=str(row.category_id) if row.category_id else None,
        description=row.description,
        target_time=row.target_time,
        status=row.status,
    )


@router.delete("/{habit_id}")
def delete_habit(habit_id: str, db: DbSession):
    row = db.get(HealthHabit, _uuid(habit_id, "Invalid habit_id"))
    if row is None:
        raise HTTPException(status_code=404, detail="Health habit not found")
    db.delete(row)
    db.commit()
    return {"ok": True, "habit_id": habit_id}


@router.get("/reminders", response_model=list[HabitReminderRead])
def list_reminders(db: DbSession, habit_id: str | None = Query(None)):
    stmt = select(HabitReminder)
    if habit_id:
        stmt = stmt.where(HabitReminder.habit_id == _uuid(habit_id, "Invalid habit_id"))
    rows = db.scalars(stmt.order_by(HabitReminder.created_at.desc())).all()
    return [
        HabitReminderRead(
            reminder_id=str(r.id),
            habit_id=str(r.habit_id),
            reminder_time=r.reminder_time,
            repeat_frequency=r.repeat_frequency,
            repeat_interval=r.repeat_interval,
            repeat_days=r.repeat_days,
            first_reminder_date=r.first_reminder_date,
            end_date=r.end_date,
            reminder_sound=r.reminder_sound,
            status=r.status,
        )
        for r in rows
    ]


@router.post("/reminders", response_model=HabitReminderRead)
def create_reminder(body: HabitReminderCreate, db: DbSession):
    row = HabitReminder(
        habit_id=_uuid(body.habit_id, "Invalid habit_id"),
        reminder_time=body.reminder_time,
        repeat_frequency=body.repeat_frequency,
        repeat_interval=body.repeat_interval,
        repeat_days=body.repeat_days,
        first_reminder_date=body.first_reminder_date,
        end_date=body.end_date,
        reminder_sound=body.reminder_sound,
        status=body.status,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return HabitReminderRead(
        reminder_id=str(row.id),
        habit_id=str(row.habit_id),
        reminder_time=row.reminder_time,
        repeat_frequency=row.repeat_frequency,
        repeat_interval=row.repeat_interval,
        repeat_days=row.repeat_days,
        first_reminder_date=row.first_reminder_date,
        end_date=row.end_date,
        reminder_sound=row.reminder_sound,
        status=row.status,
    )


@router.patch("/reminders/{reminder_id}", response_model=HabitReminderRead)
def update_reminder(reminder_id: str, body: HabitReminderUpdate, db: DbSession):
    row = db.get(HabitReminder, _uuid(reminder_id, "Invalid reminder_id"))
    if row is None:
        raise HTTPException(status_code=404, detail="Habit reminder not found")
    for key in (
        "reminder_time",
        "repeat_frequency",
        "repeat_interval",
        "repeat_days",
        "first_reminder_date",
        "end_date",
        "reminder_sound",
        "status",
    ):
        value = getattr(body, key)
        if value is not None:
            setattr(row, key, value)
    db.commit()
    db.refresh(row)
    return HabitReminderRead(
        reminder_id=str(row.id),
        habit_id=str(row.habit_id),
        reminder_time=row.reminder_time,
        repeat_frequency=row.repeat_frequency,
        repeat_interval=row.repeat_interval,
        repeat_days=row.repeat_days,
        first_reminder_date=row.first_reminder_date,
        end_date=row.end_date,
        reminder_sound=row.reminder_sound,
        status=row.status,
    )


@router.delete("/reminders/{reminder_id}")
def delete_reminder(reminder_id: str, db: DbSession):
    row = db.get(HabitReminder, _uuid(reminder_id, "Invalid reminder_id"))
    if row is None:
        raise HTTPException(status_code=404, detail="Habit reminder not found")
    db.delete(row)
    db.commit()
    return {"ok": True, "reminder_id": reminder_id}


@router.get("/logs", response_model=list[HabitLogRead])
def list_habit_logs(db: DbSession, profile_id: str | None = Query(None), habit_id: str | None = Query(None)):
    stmt = select(HabitLog).order_by(HabitLog.created_at.desc())
    if profile_id:
        stmt = stmt.where(HabitLog.profile_id == _uuid(profile_id, "Invalid profile_id"))
    if habit_id:
        stmt = stmt.where(HabitLog.habit_id == _uuid(habit_id, "Invalid habit_id"))
    rows = db.scalars(stmt).all()
    return [
        HabitLogRead(
            log_id=str(r.id),
            habit_id=str(r.habit_id),
            profile_id=str(r.profile_id),
            scheduled_datetime=r.scheduled_datetime,
            actual_datetime=r.actual_datetime,
            status=r.status,
            notes=r.notes,
        )
        for r in rows
    ]


@router.post("/logs", response_model=HabitLogRead)
def create_habit_log(body: HabitLogCreate, db: DbSession):
    row = HabitLog(
        habit_id=_uuid(body.habit_id, "Invalid habit_id"),
        profile_id=_uuid(body.profile_id, "Invalid profile_id"),
        scheduled_datetime=body.scheduled_datetime,
        actual_datetime=body.actual_datetime,
        status=body.status,
        notes=body.notes,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return HabitLogRead(
        log_id=str(row.id),
        habit_id=str(row.habit_id),
        profile_id=str(row.profile_id),
        scheduled_datetime=row.scheduled_datetime,
        actual_datetime=row.actual_datetime,
        status=row.status,
        notes=row.notes,
    )


@router.patch("/logs/{log_id}", response_model=HabitLogRead)
def update_habit_log(log_id: str, body: HabitLogUpdate, db: DbSession):
    row = db.get(HabitLog, _uuid(log_id, "Invalid log_id"))
    if row is None:
        raise HTTPException(status_code=404, detail="Habit log not found")
    if body.actual_datetime is not None:
        row.actual_datetime = body.actual_datetime
    if body.status is not None:
        row.status = body.status
    if body.notes is not None:
        row.notes = body.notes
    db.commit()
    db.refresh(row)
    return HabitLogRead(
        log_id=str(row.id),
        habit_id=str(row.habit_id),
        profile_id=str(row.profile_id),
        scheduled_datetime=row.scheduled_datetime,
        actual_datetime=row.actual_datetime,
        status=row.status,
        notes=row.notes,
    )


@router.delete("/logs/{log_id}")
def delete_habit_log(log_id: str, db: DbSession):
    row = db.get(HabitLog, _uuid(log_id, "Invalid log_id"))
    if row is None:
        raise HTTPException(status_code=404, detail="Habit log not found")
    db.delete(row)
    db.commit()
    return {"ok": True, "log_id": log_id}

