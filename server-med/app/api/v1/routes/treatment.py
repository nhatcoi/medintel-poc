"""API điều trị — danh sách thuốc, lịch uống, log tuân thủ (MVP)."""

from __future__ import annotations

import uuid
from datetime import UTC, date, datetime, time, timedelta

from fastapi import APIRouter, HTTPException, Query
from sqlalchemy import func, select

from app.api.deps import DbSession
from app.models.medical import DiseaseCategory, MedicalRecord, TreatmentPeriod
from app.models.profile import Profile
from app.models.treatment_medication import Medication, MedicationLog, MedicationSchedule
from app.repositories.medication_repository import list_medications_for_profile
from app.repositories.profile_repository import get_by_id
from app.schemas.treatment import (
    AdherenceSummaryResponse,
    MedicationCreateRequest,
    MedicationListItem,
    MedicationListResponse,
    MedicationLogCreateRequest,
    MedicationLogItem,
    MedicationLogListResponse,
    MedicationScheduleSlot,
    MedicationUpdateRequest,
)

router = APIRouter()


def _parse_hhmm(s: str) -> time:
    txt = (s or "").strip()
    try:
        hh, mm = txt.split(":")
        return time(hour=int(hh), minute=int(mm))
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=400, detail=f"Giờ không hợp lệ: {s!r}. Định dạng HH:MM") from exc


def _ensure_treatment_period(db: DbSession, profile_id: uuid.UUID) -> TreatmentPeriod:
    """MVP: nếu profile chưa có record/period thì tạo mặc định để có chỗ gắn medication."""
    rec = db.scalar(
        select(MedicalRecord)
        .where(MedicalRecord.profile_id == profile_id)
        .order_by(MedicalRecord.created_at.desc())
        .limit(1)
    )
    if rec is None:
        cat = db.scalar(
            select(DiseaseCategory).where(DiseaseCategory.category_name == "Chưa phân loại").limit(1)
        )
        rec = MedicalRecord(
            profile_id=profile_id,
            disease_name="Chưa phân loại",
            category_id=cat.id if cat else None,
            treatment_start_date=date.today(),
            treatment_status="active",
            treatment_type="long_term",
        )
        db.add(rec)
        db.flush()

    period = db.scalar(
        select(TreatmentPeriod)
        .where(TreatmentPeriod.record_id == rec.id)
        .order_by(TreatmentPeriod.created_at.desc())
        .limit(1)
    )
    if period is None:
        period = TreatmentPeriod(
            record_id=rec.id,
            period_name="Đợt điều trị hiện tại",
            start_date=date.today(),
            status="active",
        )
        db.add(period)
        db.flush()
    return period


def _ensure_profile_exists(db: DbSession, profile_id: uuid.UUID) -> Profile:
    """Local-first: tự tạo profile tối thiểu nếu client gửi profile_id mới."""
    profile = get_by_id(db, profile_id)
    if profile is not None:
        return profile
    profile = Profile(
        id=profile_id,
        full_name=f"User {str(profile_id)[:8]}",
        role="patient",
    )
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return profile


@router.get("/medications", response_model=MedicationListResponse)
def get_profile_medications(
    db: DbSession,
    profile_id: str = Query(..., description="UUID profile (bệnh nhân)"),
):
    raw = profile_id.strip()
    try:
        pid = uuid.UUID(raw)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="profile_id phải là UUID hợp lệ") from exc

    _ensure_profile_exists(db, pid)

    meds = list_medications_for_profile(db, pid)
    items: list[MedicationListItem] = []
    for m in meds:
        slots = [
            MedicationScheduleSlot(scheduled_time=f"{t.hour:02d}:{t.minute:02d}") for t in m.schedule_times
        ]
        items.append(
            MedicationListItem(
                medication_id=m.medication_id,
                name=m.name,
                dosage=m.dosage,
                frequency=m.frequency,
                instructions=m.instructions,
                status="active",
                schedule_times=slots,
            )
        )
    return MedicationListResponse(profile_id=pid, items=items)


@router.post("/medications", response_model=MedicationListItem)
def create_medication(
    body: MedicationCreateRequest,
    db: DbSession,
):
    _ensure_profile_exists(db, body.profile_id)
    period = _ensure_treatment_period(db, body.profile_id)

    med = Medication(
        period_id=period.id,
        medication_name=body.medication_name.strip(),
        dosage=body.dosage,
        frequency=body.frequency,
        instructions=body.instructions,
        start_date=body.start_date or date.today(),
        end_date=body.end_date,
        status=body.status,
        remaining_quantity=body.remaining_quantity,
        quantity_unit=body.quantity_unit,
    )
    db.add(med)
    db.flush()

    for s in body.schedule_times:
        db.add(
            MedicationSchedule(
                medication_id=med.id,
                scheduled_time=_parse_hhmm(s),
                repeat_pattern="daily",
                status="active",
            )
        )
    db.commit()
    db.refresh(med)

    slots = [MedicationScheduleSlot(scheduled_time=f"{t.hour:02d}:{t.minute:02d}") for t in sorted(
        [s.scheduled_time for s in med.schedules], key=lambda x: (x.hour, x.minute)
    )]
    return MedicationListItem(
        medication_id=med.id,
        name=med.medication_name,
        dosage=med.dosage,
        frequency=med.frequency,
        instructions=med.instructions,
        status=med.status,
        remaining_quantity=float(med.remaining_quantity) if med.remaining_quantity is not None else None,
        quantity_unit=med.quantity_unit,
        schedule_times=slots,
    )


@router.patch("/medications/{medication_id}", response_model=MedicationListItem)
def update_medication(
    medication_id: uuid.UUID,
    body: MedicationUpdateRequest,
    db: DbSession,
):
    med = db.get(Medication, medication_id)
    if med is None:
        raise HTTPException(status_code=404, detail="Không tìm thấy medication")

    for field in (
        "medication_name",
        "dosage",
        "frequency",
        "instructions",
        "status",
        "end_date",
        "remaining_quantity",
        "quantity_unit",
    ):
        value = getattr(body, field)
        if value is not None:
            setattr(med, field, value)

    if body.schedule_times is not None:
        db.query(MedicationSchedule).filter(MedicationSchedule.medication_id == med.id).delete()
        for s in body.schedule_times:
            db.add(
                MedicationSchedule(
                    medication_id=med.id,
                    scheduled_time=_parse_hhmm(s),
                    repeat_pattern="daily",
                    status="active",
                )
            )
    db.commit()
    db.refresh(med)

    slots = [MedicationScheduleSlot(scheduled_time=f"{t.hour:02d}:{t.minute:02d}") for t in sorted(
        [s.scheduled_time for s in med.schedules], key=lambda x: (x.hour, x.minute)
    )]
    return MedicationListItem(
        medication_id=med.id,
        name=med.medication_name,
        dosage=med.dosage,
        frequency=med.frequency,
        instructions=med.instructions,
        status=med.status,
        remaining_quantity=float(med.remaining_quantity) if med.remaining_quantity is not None else None,
        quantity_unit=med.quantity_unit,
        schedule_times=slots,
    )


@router.post("/medications/{medication_id}/logs", response_model=MedicationLogItem)
def create_medication_log(
    medication_id: uuid.UUID,
    body: MedicationLogCreateRequest,
    db: DbSession,
):
    _ensure_profile_exists(db, body.profile_id)
    med = db.get(Medication, medication_id)
    if med is None:
        raise HTTPException(status_code=404, detail="Không tìm thấy medication")

    schedule = db.scalar(
        select(MedicationSchedule)
        .where(MedicationSchedule.medication_id == medication_id)
        .order_by(MedicationSchedule.created_at.asc())
        .limit(1)
    )
    if schedule is None:
        raise HTTPException(status_code=400, detail="Medication chưa có lịch uống")

    now = datetime.now(UTC)
    scheduled_dt = body.scheduled_datetime or now
    actual_dt = body.actual_datetime if body.actual_datetime is not None else now
    if body.status in {"missed", "skipped"}:
        actual_dt = body.actual_datetime

    log = MedicationLog(
        schedule_id=schedule.id,
        profile_id=body.profile_id,
        scheduled_datetime=scheduled_dt,
        actual_datetime=actual_dt,
        status=body.status,
        notes=body.notes,
        logged_by_profile_id=body.profile_id,
    )
    db.add(log)
    db.commit()
    db.refresh(log)

    return MedicationLogItem(
        log_id=log.id,
        schedule_id=log.schedule_id,
        medication_id=med.id,
        medication_name=med.medication_name,
        status=log.status,
        scheduled_datetime=log.scheduled_datetime,
        actual_datetime=log.actual_datetime,
        notes=log.notes,
    )


@router.get("/medications/{medication_id}/logs", response_model=MedicationLogListResponse)
def get_medication_logs(
    medication_id: uuid.UUID,
    db: DbSession,
):
    med = db.get(Medication, medication_id)
    if med is None:
        raise HTTPException(status_code=404, detail="Không tìm thấy medication")

    stmt = (
        select(MedicationLog, MedicationSchedule)
        .join(MedicationSchedule, MedicationLog.schedule_id == MedicationSchedule.id)
        .where(MedicationSchedule.medication_id == medication_id)
        .order_by(MedicationLog.scheduled_datetime.desc())
        .limit(200)
    )
    rows = db.execute(stmt).all()
    items = [
        MedicationLogItem(
            log_id=log.id,
            schedule_id=log.schedule_id,
            medication_id=med.id,
            medication_name=med.medication_name,
            status=log.status,
            scheduled_datetime=log.scheduled_datetime,
            actual_datetime=log.actual_datetime,
            notes=log.notes,
        )
        for log, _schedule in rows
    ]
    return MedicationLogListResponse(medication_id=med.id, items=items)


@router.get("/adherence/summary", response_model=AdherenceSummaryResponse)
def get_adherence_summary(
    db: DbSession,
    profile_id: str = Query(..., description="UUID profile (bệnh nhân)"),
    days: int = Query(7, ge=1, le=60),
):
    raw = profile_id.strip()
    try:
        pid = uuid.UUID(raw)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="profile_id phải là UUID hợp lệ") from exc
    _ensure_profile_exists(db, pid)

    since = datetime.now(UTC) - timedelta(days=days)
    totals_stmt = (
        select(MedicationLog.status, func.count(MedicationLog.id))
        .where(MedicationLog.profile_id == pid, MedicationLog.scheduled_datetime >= since)
        .group_by(MedicationLog.status)
    )
    rows = db.execute(totals_stmt).all()
    counts: dict[str, int] = {str(status): int(cnt) for status, cnt in rows}
    total = sum(counts.values())
    return AdherenceSummaryResponse(
        profile_id=pid,
        days=days,
        total=total,
        taken=counts.get("taken", 0),
        missed=counts.get("missed", 0),
        skipped=counts.get("skipped", 0),
        late=counts.get("late", 0),
    )
