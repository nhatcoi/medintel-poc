from __future__ import annotations

from langchain_core.tools import tool

from agent.tools.common import parse_uuid, tool_error, tool_ok
from core.database import SessionLocal
from models.agent_context import PatientAgentContext


@tool
def update_patient_memory(profile_id: str, key: str, value: str, confidence: float = 0.9) -> str:
    """Cập nhật trí nhớ dài hạn theo profile_id vào patient_agent_context."""
    pid = parse_uuid(profile_id)
    if not pid:
        return tool_error("profile_id không hợp lệ.", code="INVALID_PROFILE_ID")
    if not (key or "").strip() or not (value or "").strip():
        return tool_error("Thiếu key/value để cập nhật memory.", code="INVALID_ARGS")

    db = SessionLocal()
    try:
        row = db.get(PatientAgentContext, pid)
        line = f"- {key.strip()}: {value.strip()} (confidence={max(0.0, min(1.0, float(confidence))):.2f})"
        if row is None:
            row = PatientAgentContext(
                profile_id=pid,
                content_markdown=f"## Long-term memory\n{line}",
                source="tool_update",
                format_version=1,
            )
            db.add(row)
        else:
            content = (row.content_markdown or "").strip()
            row.content_markdown = f"{content}\n{line}" if content else f"## Long-term memory\n{line}"
            row.source = "tool_update"
        db.commit()
        return tool_ok("Đã cập nhật trí nhớ dài hạn cho hồ sơ.", data_ref=str(pid), extra={"key": key.strip()})
    except Exception as exc:
        db.rollback()
        return tool_error(f"Lỗi cập nhật memory: {exc}")
    finally:
        db.close()
