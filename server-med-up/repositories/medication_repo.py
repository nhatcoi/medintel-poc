"""Medication queries: get meds by profile (profile -> medical_records -> treatment_periods -> medications)."""

from __future__ import annotations

import uuid
from datetime import date, datetime, time, timedelta, timezone

from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from models.medical import MedicalRecord, TreatmentPeriod
from models.medication import Medication, MedicationLog, MedicationSchedule
from models.base import utc_now


def get_medications_by_profile(db: Session, profile_id: uuid.UUID) -> list[Medication]:
    stmt = (
        select(Medication)
        .join(TreatmentPeriod, Medication.period_id == TreatmentPeriod.id)
        .join(MedicalRecord, TreatmentPeriod.record_id == MedicalRecord.id)
        .where(MedicalRecord.profile_id == profile_id)
        .order_by(Medication.medication_name)
    )
    return list(db.scalars(stmt).all())


def get_by_id(db: Session, medication_id: uuid.UUID) -> Medication | None:
    return db.get(Medication, medication_id)


def get_latest_period_id_by_profile(db: Session, profile_id: uuid.UUID) -> uuid.UUID | None:
    stmt = (
        select(TreatmentPeriod.id)
        .join(MedicalRecord, TreatmentPeriod.record_id == MedicalRecord.id)
        .where(MedicalRecord.profile_id == profile_id)
        .order_by(TreatmentPeriod.start_date.desc())
        .limit(1)
    )
    return db.scalars(stmt).first()


def ensure_latest_period_id_by_profile(db: Session, profile_id: uuid.UUID) -> uuid.UUID:
    """Return latest treatment period id, auto-create a default one if missing."""
    existing = get_latest_period_id_by_profile(db, profile_id)
    if existing is not None:
        return existing

    today = date.today()
    record = MedicalRecord(
        profile_id=profile_id,
        disease_name="General treatment",
        treatment_start_date=today,
        treatment_status="active",
        treatment_type="manual",
        notes="Auto-created for medication onboarding",
    )
    db.add(record)
    db.flush()

    period = TreatmentPeriod(
        record_id=record.id,
        period_name=f"Default period {today.isoformat()}",
        start_date=today,
        status="active",
        notes="Auto-created because no treatment period existed",
    )
    db.add(period)
    db.flush()
    return period.id


def search_medications(db: Session, q: str, limit: int = 20) -> list[Medication]:
    keyword = f"%{q.strip()}%"
    stmt = (
        select(Medication)
        .where(
            or_(
                Medication.medication_name.ilike(keyword),
                Medication.instructions.ilike(keyword),
                Medication.notes.ilike(keyword),
            )
        )
        .order_by(Medication.updated_at.desc())
        .limit(limit)
    )
    return list(db.scalars(stmt).all())


def create_medication(
    db: Session,
    *,
    period_id: uuid.UUID,
    medication_name: str,
    dosage: str | None = None,
    frequency: str | None = None,
    instructions: str | None = None,
    start_date: date | None = None,
    end_date: date | None = None,
    notes: str | None = None,
    remaining_quantity: float | None = None,
    quantity_unit: str | None = None,
) -> Medication:
    med = Medication(
        period_id=period_id,
        medication_name=medication_name,
        dosage=dosage,
        frequency=frequency,
        instructions=instructions,
        start_date=start_date or date.today(),
        end_date=end_date,
        notes=notes,
        remaining_quantity=remaining_quantity,
        quantity_unit=quantity_unit,
        status="active",
    )
    db.add(med)
    db.commit()
    db.refresh(med)
    return med


def update_medication(db: Session, med: Medication, **kwargs) -> Medication:
    for key, value in kwargs.items():
        if value is None:
            continue
        if hasattr(med, key):
            setattr(med, key, value)
    db.commit()
    db.refresh(med)
    return med


def soft_delete_medication(db: Session, med: Medication) -> Medication:
    med.status = "inactive"
    db.commit()
    db.refresh(med)
    return med


def update_inventory(
    db: Session,
    med: Medication,
    *,
    remaining_quantity: float,
    quantity_unit: str | None = None,
    low_stock_threshold: float | None = None,
) -> Medication:
    med.remaining_quantity = max(0.0, float(remaining_quantity))
    if quantity_unit is not None:
        med.quantity_unit = quantity_unit
    if low_stock_threshold is not None:
        med.notes = _upsert_threshold_note(med.notes, low_stock_threshold)
    db.commit()
    db.refresh(med)
    return med


def consume_inventory(db: Session, med: Medication, amount: float = 1.0) -> Medication:
    amount = max(0.0, float(amount))
    current = float(med.remaining_quantity or 0.0)
    med.remaining_quantity = max(0.0, current - amount)
    db.commit()
    db.refresh(med)
    return med


def low_stock_by_profile(db: Session, profile_id: uuid.UUID) -> list[dict]:
    meds = get_medications_by_profile(db, profile_id)
    out: list[dict] = []
    for m in meds:
        threshold = _extract_threshold_note(m.notes)
        if threshold is None:
            threshold = 5.0
        rq = float(m.remaining_quantity) if m.remaining_quantity is not None else None
        if rq is None:
            continue
        if rq <= threshold:
            out.append(
                {
                    "medication_id": str(m.id),
                    "medication_name": m.medication_name,
                    "remaining_quantity": rq,
                    "quantity_unit": m.quantity_unit,
                    "low_stock_threshold": threshold,
                }
            )
    return out


def _extract_threshold_note(notes: str | None) -> float | None:
    if not notes:
        return None
    marker = "[low_stock_threshold="
    start = notes.find(marker)
    if start < 0:
        return None
    end = notes.find("]", start)
    if end < 0:
        return None
    raw = notes[start + len(marker) : end]
    try:
        return float(raw)
    except ValueError:
        return None


def _upsert_threshold_note(notes: str | None, value: float) -> str:
    marker = "[low_stock_threshold="
    cleaned = (notes or "").strip()
    start = cleaned.find(marker)
    if start >= 0:
        end = cleaned.find("]", start)
        if end >= 0:
            cleaned = f"{cleaned[:start]}{cleaned[end + 1:]}".strip()
    token = f"[low_stock_threshold={float(value)}]"
    return f"{cleaned} {token}".strip()


def list_schedules(db: Session, medication_id: uuid.UUID) -> list[MedicationSchedule]:
    stmt = (
        select(MedicationSchedule)
        .where(MedicationSchedule.medication_id == medication_id)
        .order_by(MedicationSchedule.scheduled_time.asc())
    )
    return list(db.scalars(stmt).all())


def list_schedules_by_profile(db: Session, profile_id: uuid.UUID) -> list[tuple[MedicationSchedule, Medication]]:
    stmt = (
        select(MedicationSchedule, Medication)
        .join(Medication, MedicationSchedule.medication_id == Medication.id)
        .join(TreatmentPeriod, Medication.period_id == TreatmentPeriod.id)
        .join(MedicalRecord, TreatmentPeriod.record_id == MedicalRecord.id)
        .where(MedicalRecord.profile_id == profile_id)
        .order_by(MedicationSchedule.scheduled_time.asc(), Medication.medication_name.asc())
    )
    return list(db.execute(stmt).all())


def get_schedule_by_id(db: Session, schedule_id: uuid.UUID) -> MedicationSchedule | None:
    return db.get(MedicationSchedule, schedule_id)


def create_schedule(
    db: Session,
    *,
    medication_id: uuid.UUID,
    scheduled_time: time,
    status: str | None = "active",
) -> MedicationSchedule:
    row = MedicationSchedule(
        medication_id=medication_id,
        scheduled_time=scheduled_time,
        status=status,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def update_schedule(db: Session, row: MedicationSchedule, **kwargs) -> MedicationSchedule:
    for key, value in kwargs.items():
        if value is None:
            continue
        if hasattr(row, key):
            setattr(row, key, value)
    db.commit()
    db.refresh(row)
    return row


def delete_schedule(db: Session, row: MedicationSchedule) -> None:
    db.delete(row)
    db.commit()


_ALLOWED_STATUSES = {"taken", "missed", "skipped", "late"}


def normalize_log_status(
    status: str,
    *,
    scheduled_datetime: datetime,
    actual_datetime: datetime | None,
    late_grace_minutes: int = 30,
) -> str:
    val = (status or "").strip().lower()
    if val not in _ALLOWED_STATUSES:
        val = "taken"
    if val == "taken" and actual_datetime is not None:
        if actual_datetime.tzinfo is None:
            actual_datetime = actual_datetime.replace(tzinfo=timezone.utc)
        if scheduled_datetime.tzinfo is None:
            scheduled_datetime = scheduled_datetime.replace(tzinfo=timezone.utc)
        if actual_datetime > (scheduled_datetime + timedelta(minutes=late_grace_minutes)):
            return "late"
    return val


def create_log(
    db: Session,
    *,
    schedule_id: uuid.UUID,
    profile_id: uuid.UUID,
    scheduled_datetime: datetime,
    status: str,
    actual_datetime: datetime | None = None,
    notes: str | None = None,
) -> MedicationLog:
    if scheduled_datetime.tzinfo is None:
        scheduled_datetime = scheduled_datetime.replace(tzinfo=timezone.utc)
    if actual_datetime is not None and actual_datetime.tzinfo is None:
        actual_datetime = actual_datetime.replace(tzinfo=timezone.utc)
    final_status = normalize_log_status(
        status,
        scheduled_datetime=scheduled_datetime,
        actual_datetime=actual_datetime,
    )
    row = MedicationLog(
        schedule_id=schedule_id,
        profile_id=profile_id,
        scheduled_datetime=scheduled_datetime,
        actual_datetime=actual_datetime,
        status=final_status,
        notes=notes,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def list_logs_by_medication(
    db: Session,
    medication_id: uuid.UUID,
    *,
    dt_from: datetime | None = None,
    dt_to: datetime | None = None,
) -> list[MedicationLog]:
    stmt = (
        select(MedicationLog)
        .join(MedicationSchedule, MedicationLog.schedule_id == MedicationSchedule.id)
        .where(MedicationSchedule.medication_id == medication_id)
        .order_by(MedicationLog.scheduled_datetime.desc())
    )
    if dt_from is not None:
        stmt = stmt.where(MedicationLog.scheduled_datetime >= dt_from)
    if dt_to is not None:
        stmt = stmt.where(MedicationLog.scheduled_datetime <= dt_to)
    return list(db.scalars(stmt).all())


def list_logs_by_profile(
    db: Session,
    profile_id: uuid.UUID,
    *,
    dt_from: datetime | None = None,
    dt_to: datetime | None = None,
) -> list[MedicationLog]:
    stmt = (
        select(MedicationLog)
        .where(MedicationLog.profile_id == profile_id)
        .order_by(MedicationLog.scheduled_datetime.desc())
    )
    if dt_from is not None:
        stmt = stmt.where(MedicationLog.scheduled_datetime >= dt_from)
    if dt_to is not None:
        stmt = stmt.where(MedicationLog.scheduled_datetime <= dt_to)
    return list(db.scalars(stmt).all())


def get_log_by_id(db: Session, log_id: uuid.UUID) -> MedicationLog | None:
    return db.get(MedicationLog, log_id)


def update_log(db: Session, row: MedicationLog, **kwargs) -> MedicationLog:
    actual_datetime = kwargs.get("actual_datetime", row.actual_datetime)
    status = kwargs.get("status", row.status)
    final_status = normalize_log_status(
        status,
        scheduled_datetime=row.scheduled_datetime,
        actual_datetime=actual_datetime,
    )
    row.status = final_status
    if "actual_datetime" in kwargs:
        row.actual_datetime = kwargs["actual_datetime"]
    if "notes" in kwargs and kwargs["notes"] is not None:
        row.notes = kwargs["notes"]
    db.commit()
    db.refresh(row)
    return row


def delete_log(db: Session, row: MedicationLog) -> None:
    db.delete(row)
    db.commit()


def adherence_summary(db: Session, profile_id: uuid.UUID, days: int = 7) -> dict:
    now = utc_now()
    start = now - timedelta(days=days)
    stmt = select(MedicationLog).where(
        and_(
            MedicationLog.profile_id == profile_id,
            MedicationLog.scheduled_datetime >= start,
            MedicationLog.scheduled_datetime <= now,
        )
    )
    rows = list(db.scalars(stmt).all())
    total = len(rows)
    taken = sum(1 for r in rows if r.status == "taken")
    late = sum(1 for r in rows if r.status == "late")
    missed = sum(1 for r in rows if r.status == "missed")
    skipped = sum(1 for r in rows if r.status == "skipped")
    compliance = ((taken + late) / total) if total else 0.0
    on_time = (taken / total) if total else 0.0
    return {
        "total_scheduled": total,
        "taken": taken,
        "late": late,
        "missed": missed,
        "skipped": skipped,
        "compliance_rate": round(compliance, 4),
        "on_time_rate": round(on_time, 4),
    }


def _build_candidate_datetime(base_date: date, at: time) -> datetime:
    return datetime.combine(base_date, at, tzinfo=timezone.utc)


def next_dose(db: Session, profile_id: uuid.UUID) -> dict | None:
    meds = get_medications_by_profile(db, profile_id)
    now = utc_now()
    candidates: list[tuple[datetime, Medication, MedicationSchedule]] = []
    for med in meds:
        if med.status and med.status.lower() == "inactive":
            continue
        for sch in list_schedules(db, med.id):
            if sch.status and sch.status.lower() == "inactive":
                continue
            today_dt = _build_candidate_datetime(now.date(), sch.scheduled_time)
            if today_dt >= now:
                candidates.append((today_dt, med, sch))
            else:
                tomorrow_dt = _build_candidate_datetime(now.date() + timedelta(days=1), sch.scheduled_time)
                candidates.append((tomorrow_dt, med, sch))
    if not candidates:
        return None
    candidates.sort(key=lambda x: x[0])
    dt, med, sch = candidates[0]
    return {
        "medication_id": str(med.id),
        "medication_name": med.medication_name,
        "schedule_id": str(sch.id),
        "scheduled_datetime": dt,
    }


def missed_dose_check(db: Session, profile_id: uuid.UUID, grace_minutes: int = 60) -> list[dict]:
    meds = get_medications_by_profile(db, profile_id)
    now = utc_now()
    items: list[dict] = []
    for med in meds:
        if med.status and med.status.lower() == "inactive":
            continue
        for sch in list_schedules(db, med.id):
            scheduled_dt = _build_candidate_datetime(now.date(), sch.scheduled_time)
            overdue = now - scheduled_dt
            if overdue.total_seconds() <= grace_minutes * 60:
                continue
            existing = db.scalars(
                select(MedicationLog).where(
                    and_(
                        MedicationLog.schedule_id == sch.id,
                        MedicationLog.profile_id == profile_id,
                        MedicationLog.scheduled_datetime == scheduled_dt,
                    )
                )
            ).first()
            if existing is not None:
                continue
            items.append(
                {
                    "medication_id": str(med.id),
                    "medication_name": med.medication_name,
                    "schedule_id": str(sch.id),
                    "scheduled_datetime": scheduled_dt,
                    "minutes_overdue": int(overdue.total_seconds() // 60),
                }
            )
    return items
