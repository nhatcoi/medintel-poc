from __future__ import annotations

from datetime import date, datetime, timezone

from langchain_core.tools import tool
from sqlalchemy import select

from agent.tools.common import parse_time_hhmm, parse_uuid, tool_error, tool_ok
from core.database import SessionLocal
from models.care import CaregiverPatientLink
from models.habits import HabitLog, HabitReminder, HealthHabit
from models.medical import MedicalRecord
from models.profile import Profile


@tool
def append_care_note(profile_id: str, text: str) -> str:
    """Ghi chú chăm sóc nhanh vào MedicalRecord.notes gần nhất theo profile."""
    pid = parse_uuid(profile_id)
    if not pid:
        return tool_error("profile_id không hợp lệ.", code="INVALID_PROFILE_ID")
    note = (text or "").strip()
    if not note:
        return tool_error("Thiếu nội dung ghi chú.", code="INVALID_ARGS")

    db = SessionLocal()
    try:
        stmt = (
            select(MedicalRecord)
            .where(MedicalRecord.profile_id == pid)
            .order_by(MedicalRecord.created_at.desc())
            .limit(1)
        )
        row = db.scalars(stmt).first()
        if row is None:
            row = MedicalRecord(
                profile_id=pid,
                disease_name="General care notes",
                treatment_start_date=date.today(),
                treatment_status="active",
                treatment_type="care_note",
                notes=f"[{datetime.now(timezone.utc).isoformat()}] {note}",
            )
            db.add(row)
        else:
            base = (row.notes or "").strip()
            line = f"[{datetime.now(timezone.utc).isoformat()}] {note}"
            row.notes = f"{base}\n{line}" if base else line
        db.commit()
        return tool_ok("Đã lưu ghi chú chăm sóc.", data_ref=str(row.id))
    except Exception as exc:
        db.rollback()
        return tool_error(f"Lỗi lưu ghi chú chăm sóc: {exc}")
    finally:
        db.close()


@tool
def profile_get_overview(profile_id: str) -> str:
    """Đọc tổng quan profile + bệnh án gần nhất + số liên kết caregiver."""
    pid = parse_uuid(profile_id)
    if not pid:
        return tool_error("profile_id không hợp lệ.", code="INVALID_PROFILE_ID")

    db = SessionLocal()
    try:
        profile = db.get(Profile, pid)
        if profile is None:
            return tool_error("Không tìm thấy hồ sơ.", code="NOT_FOUND")
        records = list(
            db.scalars(
                select(MedicalRecord)
                .where(MedicalRecord.profile_id == pid)
                .order_by(MedicalRecord.created_at.desc())
                .limit(3)
            ).all()
        )
        links = list(
            db.scalars(
                select(CaregiverPatientLink).where(
                    (CaregiverPatientLink.patient_id == pid) | (CaregiverPatientLink.caregiver_id == pid)
                )
            ).all()
        )
        return tool_ok(
            "Đã tải tổng quan hồ sơ.",
            data_ref=str(profile.id),
            extra={
                "profile": {"full_name": profile.full_name, "role": profile.role, "phone_number": profile.phone_number},
                "medical_records": [
                    {"record_id": str(r.id), "disease_name": r.disease_name, "status": r.treatment_status} for r in records
                ],
                "care_links_count": len(links),
            },
        )
    except Exception as exc:
        return tool_error(f"Lỗi đọc hồ sơ: {exc}")
    finally:
        db.close()


@tool
def care_list_links(profile_id: str) -> str:
    """Liệt kê liên kết caregiver/patient của profile."""
    pid = parse_uuid(profile_id)
    if not pid:
        return tool_error("profile_id không hợp lệ.", code="INVALID_PROFILE_ID")
    db = SessionLocal()
    try:
        rows = list(
            db.scalars(
                select(CaregiverPatientLink)
                .where((CaregiverPatientLink.patient_id == pid) | (CaregiverPatientLink.caregiver_id == pid))
                .order_by(CaregiverPatientLink.created_at.desc())
            ).all()
        )
        items = [
            {
                "link_id": str(r.id),
                "patient_id": str(r.patient_id),
                "caregiver_id": str(r.caregiver_id),
                "relationship": r.relationship,
                "status": r.status,
            }
            for r in rows
        ]
        return tool_ok("Đã tải danh sách liên kết chăm sóc.", extra={"items": items})
    except Exception as exc:
        return tool_error(f"Lỗi tải liên kết chăm sóc: {exc}")
    finally:
        db.close()


@tool
def habit_list_by_profile(profile_id: str) -> str:
    """Liệt kê habits theo profile."""
    pid = parse_uuid(profile_id)
    if not pid:
        return tool_error("profile_id không hợp lệ.", code="INVALID_PROFILE_ID")
    db = SessionLocal()
    try:
        rows = list(
            db.scalars(
                select(HealthHabit).where(HealthHabit.profile_id == pid).order_by(HealthHabit.created_at.desc()).limit(20)
            ).all()
        )
        return tool_ok(
            "Đã tải danh sách thói quen.",
            extra={
                "items": [
                    {
                        "habit_id": str(r.id),
                        "habit_name": r.habit_name,
                        "target_time": r.target_time.strftime("%H:%M") if r.target_time else None,
                        "status": r.status,
                    }
                    for r in rows
                ]
            },
        )
    except Exception as exc:
        return tool_error(f"Lỗi tải thói quen: {exc}")
    finally:
        db.close()


@tool
def habit_create(profile_id: str, habit_name: str, target_time: str = "", status: str = "active") -> str:
    """Tạo habit mới cho profile."""
    pid = parse_uuid(profile_id)
    if not pid:
        return tool_error("profile_id không hợp lệ.", code="INVALID_PROFILE_ID")
    name = (habit_name or "").strip()
    if not name:
        return tool_error("Thiếu tên habit.", code="INVALID_ARGS")
    t = parse_time_hhmm(target_time) if target_time else None

    db = SessionLocal()
    try:
        row = HealthHabit(profile_id=pid, habit_name=name, target_time=t, status=status)
        db.add(row)
        db.commit()
        db.refresh(row)
        return tool_ok("Đã tạo thói quen mới.", data_ref=str(row.id))
    except Exception as exc:
        db.rollback()
        return tool_error(f"Lỗi tạo habit: {exc}")
    finally:
        db.close()


@tool
def habit_set_reminder(habit_id: str, reminder_time: str, repeat_frequency: str = "daily") -> str:
    """Thiết lập reminder cho habit."""
    hid = parse_uuid(habit_id)
    if not hid:
        return tool_error("habit_id không hợp lệ.", code="INVALID_HABIT_ID")
    t = parse_time_hhmm(reminder_time)
    if not t:
        return tool_error("reminder_time không hợp lệ, dùng HH:MM.", code="INVALID_TIME")

    db = SessionLocal()
    try:
        habit = db.get(HealthHabit, hid)
        if habit is None:
            return tool_error("Không tìm thấy habit.", code="NOT_FOUND")
        row = HabitReminder(
            habit_id=hid,
            reminder_time=t,
            repeat_frequency=repeat_frequency or "daily",
            first_reminder_date=date.today(),
            status="active",
        )
        db.add(row)
        db.commit()
        db.refresh(row)
        return tool_ok("Đã tạo nhắc thói quen.", data_ref=str(row.id))
    except Exception as exc:
        db.rollback()
        return tool_error(f"Lỗi tạo reminder: {exc}")
    finally:
        db.close()


@tool
def habit_log_status(habit_id: str, profile_id: str, status: str = "done", notes: str = "") -> str:
    """Ghi nhận trạng thái thực hiện habit."""
    hid = parse_uuid(habit_id)
    pid = parse_uuid(profile_id)
    if not hid or not pid:
        return tool_error("habit_id hoặc profile_id không hợp lệ.", code="INVALID_ARGS")
    db = SessionLocal()
    try:
        row = HabitLog(
            habit_id=hid,
            profile_id=pid,
            scheduled_datetime=datetime.now(timezone.utc),
            actual_datetime=datetime.now(timezone.utc),
            status=status,
            notes=(notes or "").strip() or None,
        )
        db.add(row)
        db.commit()
        db.refresh(row)
        return tool_ok("Đã ghi nhận log habit.", data_ref=str(row.id))
    except Exception as exc:
        db.rollback()
        return tool_error(f"Lỗi ghi log habit: {exc}")
    finally:
        db.close()
