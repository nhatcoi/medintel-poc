"""Medication-related tools for the agent."""

from __future__ import annotations

import uuid
from datetime import datetime, timezone, time as dtime

from langchain_core.tools import tool
from sqlalchemy import select

from agent.tools.common import parse_uuid, tool_error, tool_ok
from core.database import SessionLocal
from models.medical import MedicalRecord, TreatmentPeriod
from models.medication import Medication, MedicationLog, MedicationSchedule
from repositories import medication_repo


@tool
def log_dose(profile_id: str, medication_name: str, status: str = "taken", note: str = "", recorded_at: str = "") -> str:
    """Ghi nhận một liều thuốc vào medication_logs theo profile."""
    pid = parse_uuid(profile_id)
    if not pid:
        return tool_error("profile_id không hợp lệ.", code="INVALID_PROFILE_ID")
    med_name = (medication_name or "").strip()
    if not med_name:
        return tool_error("Thiếu tên thuốc để ghi log.", code="INVALID_ARGS")

    db = SessionLocal()
    try:
        stmt = (
            select(Medication, MedicationSchedule)
            .join(MedicationSchedule, MedicationSchedule.medication_id == Medication.id)
            .join(TreatmentPeriod, Medication.period_id == TreatmentPeriod.id)
            .join(MedicalRecord, TreatmentPeriod.record_id == MedicalRecord.id)
            .where(MedicalRecord.profile_id == pid)
            .where(Medication.medication_name.ilike(f"%{med_name}%"))
            .order_by(MedicationSchedule.scheduled_time.asc())
        )
        row = db.execute(stmt).first()
        if not row:
            return tool_error(f"Không tìm thấy thuốc '{med_name}' trong tủ thuốc của bạn.", code="NOT_FOUND")
        med, sch = row
        actual_at = None
        if recorded_at.strip():
            try:
                actual_at = datetime.fromisoformat(recorded_at.strip())
            except Exception:
                actual_at = None
        log = MedicationLog(
            schedule_id=sch.id,
            profile_id=pid,
            scheduled_datetime=datetime.now(timezone.utc),
            actual_datetime=actual_at or datetime.now(timezone.utc),
            status=(status or "taken").strip(),
            notes=(note or "").strip() or None,
        )
        db.add(log)
        db.commit()
        db.refresh(log)
        return tool_ok(f"Đã ghi nhận liều {med.medication_name}: {log.status}.", data_ref=str(log.id))
    except Exception as exc:
        db.rollback()
        return tool_error(f"Lỗi ghi nhận liều: {exc}")
    finally:
        db.close()


@tool
def upsert_medication(
    name: str,
    profile_id: str = "",
    dosage_label: str = "",
    schedule_hint: str = "",
) -> str:
    """Them hoac cap nhat thuoc trong danh sach benh nhan va co the tao lich uong."""
    med_name = (name or "").strip()
    if not med_name:
        return tool_error("Không thể thêm thuốc vì thiếu tên thuốc.", code="INVALID_ARGS")
    pid = parse_uuid(profile_id)
    if not pid:
        return tool_error("Không thể thêm thuốc vì profile_id không hợp lệ.", code="INVALID_PROFILE_ID")

    db = SessionLocal()
    try:
        period_id = medication_repo.ensure_latest_period_id_by_profile(db, pid)
        med = medication_repo.create_medication(
            db,
            period_id=period_id,
            medication_name=med_name,
            dosage=(dosage_label or "").strip() or None,
            start_date=datetime.now(timezone.utc).date(),
        )

        created_times: list[str] = []
        raw_hint = (schedule_hint or "").strip()
        if raw_hint:
            parts = [p.strip() for p in raw_hint.replace(".", ":").replace(";", ",").split(",")]
            for p in parts:
                if not p:
                    continue
                token = p.lower().replace("h", ":")
                if token.endswith(":"):
                    token += "00"
                hhmm = token[:5]
                try:
                    hh, mm = hhmm.split(":", 1)
                    t = dtime(hour=max(0, min(23, int(hh))), minute=max(0, min(59, int(mm))))
                except Exception:
                    continue
                medication_repo.create_schedule(db, medication_id=med.id, scheduled_time=t, status="active")
                created_times.append(t.strftime("%H:%M"))

        if created_times:
            return tool_ok(
                f"Đã thêm thuốc {med.medication_name} thành công, lịch uống: {', '.join(created_times)}.",
                data_ref=str(med.id),
            )
        return tool_ok(f"Đã thêm thuốc {med.medication_name} thành công.", data_ref=str(med.id))
    except Exception as exc:
        db.rollback()
        return tool_error(f"Không thể thêm thuốc lúc này: {exc}")
    finally:
        db.close()


@tool
def get_today_medications(profile_id: str) -> str:
    """Lay danh sach thuoc can uong hom nay cua benh nhan."""
    pid = parse_uuid(profile_id)
    if not pid:
        return tool_error("Không tìm thấy profile hợp lệ để lấy lịch thuốc.", code="INVALID_PROFILE_ID")

    db = SessionLocal()
    try:
        stmt = (
            select(Medication, MedicationSchedule)
            .join(MedicationSchedule, MedicationSchedule.medication_id == Medication.id)
            .join(TreatmentPeriod, Medication.period_id == TreatmentPeriod.id)
            .join(MedicalRecord, TreatmentPeriod.record_id == MedicalRecord.id)
            .where(MedicalRecord.profile_id == pid)
            .order_by(MedicationSchedule.scheduled_time.asc(), Medication.medication_name.asc())
        )
        rows = db.execute(stmt).all()
        if not rows:
            return tool_ok("Hôm nay bạn chưa có lịch uống thuốc nào.", extra={"items": []})

        lines = []
        for med, sch in rows:
            med_status = (med.status or "active").lower()
            sch_status = (sch.status or "active").lower()
            if med_status != "active" or sch_status != "active":
                continue
            hhmm = sch.scheduled_time.strftime("%H:%M")
            dose = (med.dosage or "").strip()
            freq = (med.frequency or "").strip()
            extras = " | ".join(x for x in [dose, freq] if x)
            if extras:
                lines.append(f"- {hhmm} - {med.medication_name} ({extras})")
            else:
                lines.append(f"- {hhmm} - {med.medication_name}")
        if not lines:
            return tool_ok("Hôm nay bạn chưa có lịch uống thuốc nào.", extra={"items": []})

        now_local = datetime.now(timezone.utc).astimezone().strftime("%d/%m %H:%M")
        return tool_ok(
            f"Lịch uống thuốc hôm nay (cập nhật lúc {now_local}).",
            extra={"items": lines[:20]},
        )
    finally:
        db.close()


@tool
def med_list_cabinet(profile_id: str) -> str:
    """Liệt kê tủ thuốc cá nhân theo profile."""
    pid = parse_uuid(profile_id)
    if not pid:
        return tool_error("profile_id không hợp lệ.", code="INVALID_PROFILE_ID")
    db = SessionLocal()
    try:
        meds = medication_repo.get_medications_by_profile(db, pid)
        items = [
            {
                "medication_id": str(m.id),
                "name": m.medication_name,
                "dosage": m.dosage,
                "frequency": m.frequency,
                "remaining_quantity": float(m.remaining_quantity) if m.remaining_quantity is not None else None,
                "quantity_unit": m.quantity_unit,
                "status": m.status,
            }
            for m in meds
        ]
        return tool_ok("Đã tải tủ thuốc cá nhân.", extra={"items": items})
    except Exception as exc:
        return tool_error(f"Lỗi tải tủ thuốc: {exc}")
    finally:
        db.close()
