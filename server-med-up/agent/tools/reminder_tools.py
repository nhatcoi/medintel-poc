from __future__ import annotations

from datetime import datetime

from langchain_core.tools import tool

from agent.tools.common import parse_uuid, parse_time_hhmm, tool_error, tool_ok
from core.database import SessionLocal
from models.reporting import Notification


@tool
def save_reminder_intent(profile_id: str, title: str, detail: str = "", remind_at: str = "") -> str:
    """Lưu ý định nhắc việc dưới dạng notification draft cho đúng profile."""
    pid = parse_uuid(profile_id)
    if not pid:
        return tool_error("profile_id không hợp lệ.", code="INVALID_PROFILE_ID")
    if not (title or "").strip():
        return tool_error("Thiếu tiêu đề nhắc.", code="INVALID_ARGS")

    scheduled_for = None
    if remind_at.strip():
        try:
            scheduled_for = datetime.fromisoformat(remind_at.strip())
        except Exception:
            hhmm = parse_time_hhmm(remind_at)
            if hhmm:
                now = datetime.now().astimezone()
                scheduled_for = now.replace(hour=hhmm.hour, minute=hhmm.minute, second=0, microsecond=0)

    db = SessionLocal()
    try:
        row = Notification(
            profile_id=pid,
            notification_type="reminder_intent",
            title=title.strip(),
            message=(detail or "").strip() or "Reminder requested by agent",
            scheduled_for=scheduled_for,
        )
        db.add(row)
        db.commit()
        db.refresh(row)
        return tool_ok("Đã lưu ý định nhắc việc.", data_ref=str(row.id))
    except Exception as exc:
        db.rollback()
        return tool_error(f"Lỗi lưu reminder intent: {exc}")
    finally:
        db.close()
