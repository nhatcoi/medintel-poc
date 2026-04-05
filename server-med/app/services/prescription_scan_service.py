"""Chuẩn hoá kết quả LLM và ghi medical_records → treatment_periods → medications → schedules."""

from __future__ import annotations

import uuid
from datetime import UTC, date, datetime, time

from sqlalchemy.orm import Session

from app.models.medical import MedicalRecord, TreatmentPeriod
from app.models.treatment_medication import Medication, MedicationSchedule
from app.schemas.scan import ScanResult, SavedMedicationRef


def normalize_llm_scan_dict(raw: dict) -> dict:
    """Đảm bảo cấu trúc khớp [ScanResult] (tên thuốc bắt buộc)."""
    meds: list[dict] = []
    for m in raw.get("medications") or []:
        if not isinstance(m, dict):
            continue
        name = (m.get("name") or "").strip() or "Chưa rõ"
        times = m.get("times")
        if not isinstance(times, list):
            times = []
        times = [str(t) for t in times if t is not None]
        meds.append(
            {
                "name": name,
                "dosage": m.get("dosage"),
                "frequency": m.get("frequency"),
                "instructions": m.get("instructions"),
                "times": times,
            }
        )
    return {
        "doctor_name": raw.get("doctor_name"),
        "issued_date": raw.get("issued_date"),
        "patient_name": raw.get("patient_name"),
        "raw_text": raw.get("raw_text"),
        "medications": meds,
    }


def _parse_issued_at(issued_date: str | None) -> datetime | None:
    if not issued_date or not str(issued_date).strip():
        return None
    s = str(issued_date).strip()[:10]
    try:
        d = date.fromisoformat(s)
        return datetime(d.year, d.month, d.day, tzinfo=UTC)
    except ValueError:
        return None


def _parse_hh_mm(t: str) -> time | None:
    t = str(t).strip()
    if not t:
        return None
    parts = t.replace(".", ":").split(":")
    if len(parts) < 2:
        return None
    try:
        h = max(0, min(23, int(parts[0])))
        m = max(0, min(59, int(parts[1])))
        return time(hour=h, minute=m)
    except ValueError:
        return None


def persist_scan_result(
    db: Session,
    *,
    profile_id: uuid.UUID,
    scan: ScanResult,
) -> tuple[uuid.UUID, list[SavedMedicationRef]]:
    """Tạo bản ghi điều trị từ OCR; `prescription_id` API = medical_records.record_id; commit trong hàm."""
    issued_at = _parse_issued_at(scan.issued_date)
    start_d = issued_at.date() if issued_at else date.today()

    notes_parts: list[str] = []
    if scan.patient_name:
        notes_parts.append(f"Bệnh nhân (OCR): {scan.patient_name}")

    record = MedicalRecord(
        profile_id=profile_id,
        disease_name="Từ đơn thuốc (OCR)",
        treatment_start_date=start_d,
        scan_raw_ocr=scan.raw_text,
        notes="\n".join(notes_parts) if notes_parts else None,
    )
    db.add(record)
    db.flush()

    period = TreatmentPeriod(
        record_id=record.id,
        period_name="Đơn quét",
        start_date=start_d,
        status="active",
    )
    db.add(period)
    db.flush()

    saved: list[SavedMedicationRef] = []

    for item in scan.medications:
        med = Medication(
            period_id=period.id,
            medication_name=item.name,
            dosage=item.dosage,
            frequency=item.frequency,
            instructions=item.instructions,
            start_date=start_d,
            prescribing_doctor=scan.doctor_name,
            prescription_date=start_d if issued_at else None,
        )
        db.add(med)
        db.flush()

        times = item.times if item.times else ["08:00"]
        added_schedule = False
        for tstr in times:
            tod = _parse_hh_mm(tstr)
            if tod is None:
                continue
            db.add(
                MedicationSchedule(
                    medication_id=med.id,
                    scheduled_time=tod,
                )
            )
            added_schedule = True
        if not added_schedule:
            db.add(
                MedicationSchedule(
                    medication_id=med.id,
                    scheduled_time=time(8, 0),
                )
            )

        saved.append(SavedMedicationRef(id=str(med.id), name=item.name))

    try:
        db.commit()
    except Exception:
        db.rollback()
        raise

    db.refresh(record)
    return record.id, saved
