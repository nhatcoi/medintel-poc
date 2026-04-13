import uuid
from datetime import datetime

from fastapi import APIRouter, HTTPException, Query

from api.deps import DbSession
from repositories import medication_repo
from schemas.treatment import (
    AdherenceSummary,
    LogCreate,
    LogRead,
    LogUpdate,
    MedicationCreate,
    MedicationListResponse,
    MedicationRead,
    MedicationSearchItem,
    MedicationSearchResponse,
    MedicationUpdate,
    MissedDoseCheckResponse,
    MissedDoseItem,
    NextDoseResponse,
    ScheduleCreate,
    ScheduleRead,
    ScheduleUpdate,
)

router = APIRouter(prefix="/treatment", tags=["treatment"])


def _to_med_read(m) -> MedicationRead:
    return MedicationRead(
        medication_id=str(m.id),
        medication_name=m.medication_name,
        dosage=m.dosage,
        frequency=m.frequency,
        start_date=m.start_date,
        end_date=m.end_date,
        instructions=m.instructions,
        status=m.status,
        period_id=str(m.period_id),
    )


def _to_schedule_read(s, medication_name: str | None = None) -> ScheduleRead:
    return ScheduleRead(
        schedule_id=str(s.id),
        medication_id=str(s.medication_id),
        medication_name=medication_name,
        scheduled_time=s.scheduled_time,
        reminder_enabled=s.reminder_enabled,
        status=s.status,
    )


def _to_log_read(log, medication_id: str | None = None, medication_name: str | None = None) -> LogRead:
    return LogRead(
        log_id=str(log.id),
        schedule_id=str(log.schedule_id),
        medication_id=medication_id,
        medication_name=medication_name,
        status=log.status,
        scheduled_datetime=log.scheduled_datetime,
        actual_datetime=log.actual_datetime,
        notes=log.notes,
    )


@router.get("/medications/search", response_model=MedicationSearchResponse)
def search_medications(db: DbSession, q: str = Query(..., min_length=1), limit: int = Query(20, ge=1, le=50)):
    items = medication_repo.search_medications(db, q, limit=limit)
    return MedicationSearchResponse(
        items=[
            MedicationSearchItem(
                medication_id=str(m.id),
                medication_name=m.medication_name,
                active_ingredient=m.active_ingredient,
                indications=m.instructions,
            )
            for m in items
        ]
    )


@router.get("/medications", response_model=MedicationListResponse)
def get_medications(db: DbSession, profile_id: str = Query(...)):
    try:
        pid = uuid.UUID(profile_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid UUID") from exc
    meds = medication_repo.get_medications_by_profile(db, pid)
    return MedicationListResponse(medications=[_to_med_read(m) for m in meds])


@router.post("/medications", response_model=MedicationRead)
def create_medication(body: MedicationCreate, db: DbSession):
    try:
        pid = uuid.UUID(body.profile_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid profile UUID") from exc

    period_id: uuid.UUID | None = None
    if body.period_id and body.period_id.strip():
        try:
            period_id = uuid.UUID(body.period_id.strip())
        except ValueError as exc:
            raise HTTPException(status_code=400, detail="Invalid period UUID") from exc
    else:
        period_id = medication_repo.ensure_latest_period_id_by_profile(db, pid)

    med = medication_repo.create_medication(
        db,
        period_id=period_id,
        medication_name=body.medication_name,
        dosage=body.dosage,
        frequency=body.frequency,
        instructions=body.instructions,
        start_date=body.start_date,
        end_date=body.end_date,
        notes=body.notes,
    )
    return _to_med_read(med)


@router.patch("/medications/{medication_id}", response_model=MedicationRead)
def update_medication(medication_id: str, body: MedicationUpdate, db: DbSession):
    try:
        mid = uuid.UUID(medication_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid medication UUID") from exc

    med = medication_repo.get_by_id(db, mid)
    if med is None:
        raise HTTPException(status_code=404, detail="Medication not found")

    updated = medication_repo.update_medication(
        db,
        med,
        medication_name=body.medication_name,
        dosage=body.dosage,
        frequency=body.frequency,
        instructions=body.instructions,
        start_date=body.start_date,
        end_date=body.end_date,
        status=body.status,
        notes=body.notes,
    )
    return _to_med_read(updated)


@router.delete("/medications/{medication_id}")
def delete_medication(medication_id: str, db: DbSession):
    try:
        mid = uuid.UUID(medication_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid medication UUID") from exc
    med = medication_repo.get_by_id(db, mid)
    if med is None:
        raise HTTPException(status_code=404, detail="Medication not found")
    medication_repo.soft_delete_medication(db, med)
    return {"ok": True, "medication_id": medication_id, "status": "inactive"}


@router.get("/medications/{medication_id}/schedules", response_model=list[ScheduleRead])
def list_schedules(medication_id: str, db: DbSession):
    try:
        mid = uuid.UUID(medication_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid medication UUID") from exc
    med = medication_repo.get_by_id(db, mid)
    if med is None:
        raise HTTPException(status_code=404, detail="Medication not found")
    rows = medication_repo.list_schedules(db, mid)
    return [_to_schedule_read(s, medication_name=med.medication_name) for s in rows]


@router.post("/medications/{medication_id}/schedules", response_model=ScheduleRead)
def create_schedule(medication_id: str, body: ScheduleCreate, db: DbSession):
    try:
        mid = uuid.UUID(medication_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid medication UUID") from exc
    med = medication_repo.get_by_id(db, mid)
    if med is None:
        raise HTTPException(status_code=404, detail="Medication not found")
    row = medication_repo.create_schedule(
        db,
        medication_id=mid,
        scheduled_time=body.scheduled_time,
        repeat_pattern=body.repeat_pattern,
        repeat_days=body.repeat_days,
        start_date=body.start_date,
        end_date=body.end_date,
        reminder_enabled=body.reminder_enabled,
        reminder_time_before=body.reminder_time_before,
        reminder_sound=body.reminder_sound,
        status=body.status,
    )
    return _to_schedule_read(row, medication_name=med.medication_name)


@router.patch("/medications/{medication_id}/schedules/{schedule_id}", response_model=ScheduleRead)
def update_schedule(medication_id: str, schedule_id: str, body: ScheduleUpdate, db: DbSession):
    try:
        mid = uuid.UUID(medication_id.strip())
        sid = uuid.UUID(schedule_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid UUID") from exc
    med = medication_repo.get_by_id(db, mid)
    if med is None:
        raise HTTPException(status_code=404, detail="Medication not found")
    row = medication_repo.get_schedule_by_id(db, sid)
    if row is None or row.medication_id != mid:
        raise HTTPException(status_code=404, detail="Schedule not found")
    updated = medication_repo.update_schedule(
        db,
        row,
        scheduled_time=body.scheduled_time,
        repeat_pattern=body.repeat_pattern,
        repeat_days=body.repeat_days,
        start_date=body.start_date,
        end_date=body.end_date,
        reminder_enabled=body.reminder_enabled,
        reminder_time_before=body.reminder_time_before,
        reminder_sound=body.reminder_sound,
        status=body.status,
    )
    return _to_schedule_read(updated, medication_name=med.medication_name)


@router.delete("/medications/{medication_id}/schedules/{schedule_id}")
def delete_schedule(medication_id: str, schedule_id: str, db: DbSession):
    try:
        mid = uuid.UUID(medication_id.strip())
        sid = uuid.UUID(schedule_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid UUID") from exc
    row = medication_repo.get_schedule_by_id(db, sid)
    if row is None or row.medication_id != mid:
        raise HTTPException(status_code=404, detail="Schedule not found")
    medication_repo.delete_schedule(db, row)
    return {"ok": True, "schedule_id": schedule_id}


@router.get("/medications/{medication_id}/logs", response_model=list[LogRead])
def list_logs(
    medication_id: str,
    db: DbSession,
    dt_from: str | None = Query(None),
    dt_to: str | None = Query(None),
):
    try:
        mid = uuid.UUID(medication_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid medication UUID") from exc
    med = medication_repo.get_by_id(db, mid)
    if med is None:
        raise HTTPException(status_code=404, detail="Medication not found")

    parsed_from = datetime.fromisoformat(dt_from) if dt_from else None
    parsed_to = datetime.fromisoformat(dt_to) if dt_to else None
    rows = medication_repo.list_logs_by_medication(db, mid, dt_from=parsed_from, dt_to=parsed_to)
    return [_to_log_read(r, medication_id=str(mid), medication_name=med.medication_name) for r in rows]


@router.post("/medications/{medication_id}/logs", response_model=LogRead)
def create_log(medication_id: str, body: LogCreate, db: DbSession):
    try:
        mid = uuid.UUID(medication_id.strip())
        sid = uuid.UUID(body.schedule_id.strip())
        pid = uuid.UUID(body.profile_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid UUID") from exc
    med = medication_repo.get_by_id(db, mid)
    if med is None:
        raise HTTPException(status_code=404, detail="Medication not found")
    sch = medication_repo.get_schedule_by_id(db, sid)
    if sch is None or sch.medication_id != mid:
        raise HTTPException(status_code=404, detail="Schedule not found")

    row = medication_repo.create_log(
        db,
        schedule_id=sid,
        profile_id=pid,
        scheduled_datetime=body.scheduled_datetime,
        status=body.status,
        actual_datetime=body.actual_datetime,
        notes=body.notes,
    )
    return _to_log_read(row, medication_id=str(mid), medication_name=med.medication_name)


@router.patch("/medications/{medication_id}/logs/{log_id}", response_model=LogRead)
def update_log(medication_id: str, log_id: str, body: LogUpdate, db: DbSession):
    try:
        mid = uuid.UUID(medication_id.strip())
        lid = uuid.UUID(log_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid UUID") from exc
    med = medication_repo.get_by_id(db, mid)
    if med is None:
        raise HTTPException(status_code=404, detail="Medication not found")
    row = medication_repo.get_log_by_id(db, lid)
    if row is None:
        raise HTTPException(status_code=404, detail="Log not found")
    sch = medication_repo.get_schedule_by_id(db, row.schedule_id)
    if sch is None or sch.medication_id != mid:
        raise HTTPException(status_code=404, detail="Log not found for this medication")
    updated = medication_repo.update_log(
        db,
        row,
        status=body.status,
        actual_datetime=body.actual_datetime,
        notes=body.notes,
    )
    return _to_log_read(updated, medication_id=str(mid), medication_name=med.medication_name)


@router.delete("/medications/{medication_id}/logs/{log_id}")
def delete_log(medication_id: str, log_id: str, db: DbSession):
    try:
        mid = uuid.UUID(medication_id.strip())
        lid = uuid.UUID(log_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid UUID") from exc
    row = medication_repo.get_log_by_id(db, lid)
    if row is None:
        raise HTTPException(status_code=404, detail="Log not found")
    sch = medication_repo.get_schedule_by_id(db, row.schedule_id)
    if sch is None or sch.medication_id != mid:
        raise HTTPException(status_code=404, detail="Log not found for this medication")
    medication_repo.delete_log(db, row)
    return {"ok": True, "log_id": log_id}


@router.get("/adherence/summary", response_model=AdherenceSummary)
def get_adherence_summary(db: DbSession, profile_id: str = Query(...), days: int = Query(7, ge=1, le=365)):
    try:
        pid = uuid.UUID(profile_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid profile UUID") from exc
    summary = medication_repo.adherence_summary(db, pid, days=days)
    return AdherenceSummary(profile_id=profile_id, days=days, **summary)


@router.get("/next-dose", response_model=NextDoseResponse)
def get_next_dose(db: DbSession, profile_id: str = Query(...)):
    try:
        pid = uuid.UUID(profile_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid profile UUID") from exc
    row = medication_repo.next_dose(db, pid)
    if row is None:
        raise HTTPException(status_code=404, detail="No upcoming dose found")
    return NextDoseResponse(**row)


@router.get("/missed-dose-check", response_model=MissedDoseCheckResponse)
def get_missed_dose_check(db: DbSession, profile_id: str = Query(...), grace_minutes: int = Query(60, ge=0, le=720)):
    try:
        pid = uuid.UUID(profile_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid profile UUID") from exc
    items = medication_repo.missed_dose_check(db, pid, grace_minutes=grace_minutes)
    return MissedDoseCheckResponse(
        profile_id=profile_id,
        items=[MissedDoseItem(**item) for item in items],
    )
