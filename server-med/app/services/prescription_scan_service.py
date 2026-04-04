"""Chuẩn hoá kết quả LLM và ghi Prescription + Medication + MedicationSchedule."""

from __future__ import annotations

import uuid
from datetime import UTC, date, datetime, time

from sqlalchemy.orm import Session

from app.models.medication import Medication, MedicationSchedule
from app.models.prescription import Prescription
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
    user_id: uuid.UUID,
    scan: ScanResult,
) -> tuple[uuid.UUID, list[SavedMedicationRef]]:
    """Tạo bản ghi đơn thuốc và lịch uống thuốc; commit trong hàm."""
    issued_at = _parse_issued_at(scan.issued_date)

    rx = Prescription(
        user_id=user_id,
        image_url=None,
        raw_ocr_text=scan.raw_text,
        doctor_name=scan.doctor_name,
        issued_at=issued_at,
        valid_until=None,
    )
    db.add(rx)
    db.flush()

    saved: list[SavedMedicationRef] = []

    for item in scan.medications:
        med = Medication(
            prescription_id=rx.id,
            name=item.name,
            dosage=item.dosage,
            frequency=item.frequency,
            instructions=item.instructions,
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
                    time_of_day=tod,
                    days_of_week=None,
                )
            )
            added_schedule = True
        if not added_schedule:
            db.add(
                MedicationSchedule(
                    medication_id=med.id,
                    time_of_day=time(8, 0),
                    days_of_week=None,
                )
            )

        saved.append(SavedMedicationRef(id=str(med.id), name=med.name))

    try:
        db.commit()
    except Exception:
        db.rollback()
        raise

    db.refresh(rx)
    return rx.id, saved
