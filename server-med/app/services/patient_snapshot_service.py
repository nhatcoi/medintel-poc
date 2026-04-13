"""Gom dữ liệu profile + thuốc + log + memory cho API snapshot."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.models.medical import MedicalRecord, TreatmentPeriod
from app.models.patient_memory import PatientMemory
from app.models.profile import Device, Profile
from app.models.treatment_medication import Medication, MedicationLog, MedicationSchedule
from app.schemas.medical_records import MedicalRecordRead
from app.schemas.memory import MemoryRead
from app.schemas.profile_snapshot import (
    DeviceSnapshotItem,
    MedicationCabinetItem,
    MedicationLogSnapshotItem,
    MedicationScheduleDetail,
    ProfileSnapshotProfile,
    ProfileSnapshotResponse,
)
from app.schemas.treatment import AdherenceSummaryResponse, MedicationScheduleSlot


def _adherence_summary(db: Session, profile_id: uuid.UUID, days: int = 7) -> AdherenceSummaryResponse:
    since = datetime.now(UTC) - timedelta(days=days)
    totals_stmt = (
        select(MedicationLog.status, func.count(MedicationLog.id))
        .where(MedicationLog.profile_id == profile_id, MedicationLog.scheduled_datetime >= since)
        .group_by(MedicationLog.status)
    )
    rows = db.execute(totals_stmt).all()
    counts: dict[str, int] = {str(status): int(cnt) for status, cnt in rows}
    total = sum(counts.values())
    return AdherenceSummaryResponse(
        profile_id=profile_id,
        days=days,
        total=total,
        taken=counts.get("taken", 0),
        missed=counts.get("missed", 0),
        skipped=counts.get("skipped", 0),
        late=counts.get("late", 0),
    )


def build_patient_snapshot(
    db: Session,
    profile_id: uuid.UUID,
    *,
    log_limit: int = 100,
    adherence_days: int = 7,
) -> ProfileSnapshotResponse | None:
    p = db.get(Profile, profile_id)
    if p is None:
        return None

    profile = ProfileSnapshotProfile(
        profile_id=p.id,
        full_name=p.full_name,
        date_of_birth=p.date_of_birth,
        emergency_contact=p.emergency_contact,
        role=p.role,
        email=p.email,
        phone_number=p.phone_number,
        last_server_sync_at=p.last_server_sync_at,
        created_at=p.created_at,
    )

    dev_rows = db.scalars(select(Device).where(Device.profile_id == profile_id)).all()
    devices = [
        DeviceSnapshotItem(
            device_id=d.id,
            device_label=d.device_label,
            platform=d.platform,
            last_seen_at=d.last_seen_at,
        )
        for d in dev_rows
    ]

    rec_rows = db.scalars(
        select(MedicalRecord)
        .where(MedicalRecord.profile_id == profile_id)
        .order_by(MedicalRecord.treatment_start_date.desc())
    ).all()
    medical_records = [
        MedicalRecordRead(
            record_id=r.id,
            profile_id=r.profile_id,
            disease_name=r.disease_name,
            category_id=r.category_id,
            treatment_start_date=r.treatment_start_date,
            treatment_status=r.treatment_status,
            treatment_type=r.treatment_type,
            notes=r.notes,
            scan_image_url=r.scan_image_url,
            created_at=r.created_at,
        )
        for r in rec_rows
    ]

    med_stmt = (
        select(Medication)
        .join(TreatmentPeriod, Medication.period_id == TreatmentPeriod.id)
        .join(MedicalRecord, TreatmentPeriod.record_id == MedicalRecord.id)
        .where(MedicalRecord.profile_id == profile_id)
        .options(selectinload(Medication.schedules))
        .order_by(Medication.medication_name)
    )
    med_rows = db.scalars(med_stmt).unique().all()

    medication_cabinet: list[MedicationCabinetItem] = []
    for med in med_rows:
        scheds = sorted(med.schedules or [], key=lambda s: (s.scheduled_time.hour, s.scheduled_time.minute))
        slots = [MedicationScheduleSlot(scheduled_time=f"{s.scheduled_time.hour:02d}:{s.scheduled_time.minute:02d}") for s in scheds]
        detail = [
            MedicationScheduleDetail(
                schedule_id=s.id,
                scheduled_time=f"{s.scheduled_time.hour:02d}:{s.scheduled_time.minute:02d}",
                repeat_pattern=s.repeat_pattern,
                status=s.status,
                reminder_enabled=s.reminder_enabled,
            )
            for s in scheds
        ]
        medication_cabinet.append(
            MedicationCabinetItem(
                medication_id=med.id,
                name=(med.medication_name or "").strip() or "Chưa rõ",
                dosage=med.dosage,
                frequency=med.frequency,
                instructions=med.instructions,
                status=med.status,
                start_date=med.start_date,
                end_date=med.end_date,
                active_ingredient=med.active_ingredient,
                strength=med.strength,
                dosage_form=med.dosage_form,
                route=med.route,
                remaining_quantity=float(med.remaining_quantity) if med.remaining_quantity is not None else None,
                quantity_unit=med.quantity_unit,
                total_quantity=float(med.total_quantity) if med.total_quantity is not None else None,
                prescribing_doctor=med.prescribing_doctor,
                prescription_number=med.prescription_number,
                prescription_date=med.prescription_date,
                notes=med.notes,
                schedule_times=slots,
                schedules_detail=detail,
            )
        )

    log_stmt = (
        select(MedicationLog, Medication)
        .join(MedicationSchedule, MedicationLog.schedule_id == MedicationSchedule.id)
        .join(Medication, MedicationSchedule.medication_id == Medication.id)
        .where(MedicationLog.profile_id == profile_id)
        .order_by(MedicationLog.scheduled_datetime.desc())
        .limit(log_limit)
    )
    log_rows = db.execute(log_stmt).all()
    medication_logs_recent = [
        MedicationLogSnapshotItem(
            log_id=log.id,
            schedule_id=log.schedule_id,
            medication_id=med.id,
            medication_name=med.medication_name,
            status=log.status,
            scheduled_datetime=log.scheduled_datetime,
            actual_datetime=log.actual_datetime,
            notes=log.notes,
        )
        for log, med in log_rows
    ]

    mem_rows = db.scalars(
        select(PatientMemory)
        .where(PatientMemory.profile_id == profile_id)
        .order_by(PatientMemory.key)
    ).all()
    memories = [
        MemoryRead(
            memory_id=m.id,
            profile_id=m.profile_id,
            key=m.key,
            value=m.value,
            source=m.source,
            confidence=m.confidence,
        )
        for m in mem_rows
    ]

    adherence = _adherence_summary(db, profile_id, days=adherence_days)

    return ProfileSnapshotResponse(
        profile=profile,
        devices=devices,
        medical_records=medical_records,
        medication_cabinet=medication_cabinet,
        medication_logs_recent=medication_logs_recent,
        memories=memories,
        adherence_summary=adherence,
    )
