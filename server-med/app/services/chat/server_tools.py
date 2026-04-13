"""Thực thi tool_calls phía server (ví dụ update_patient_memory)."""

from __future__ import annotations

import uuid

from sqlalchemy.orm import Session

from app.services.agent.registry import SERVER_SIDE_TOOLS
from app.services.memory.long_term import upsert_memory
from app.services.patient_agent_context_service import refresh_patient_agent_context_best_effort


def execute_server_tools(
    db: Session,
    profile_id: uuid.UUID | None,
    tool_calls: list[dict],
) -> tuple[list[dict], list[dict]]:
    """Thực thi các server-side tool_calls ngay trên server.

    Trả về (client_tools, executed_tools):
    - client_tools: những tool còn lại để trả về app
    - executed_tools: những tool đã chạy server-side (để log)
    """
    client_tools: list[dict] = []
    executed: list[dict] = []

    for tc in tool_calls:
        tool_name = tc.get("tool", "")
        if tool_name not in SERVER_SIDE_TOOLS:
            client_tools.append(tc)
            continue

        args = tc.get("args") or {}
        try:
            if tool_name == "update_patient_memory" and profile_id is not None:
                key = str(args.get("key") or "").strip()
                value = args.get("value")
                confidence = float(args.get("confidence") or 0.9)
                if key and value is not None:
                    upsert_memory(
                        db,
                        profile_id,
                        key,
                        value,
                        source="llm_inferred",
                        confidence=min(max(confidence, 0.0), 1.0),
                    )
                    db.commit()
                    refresh_patient_agent_context_best_effort(db, profile_id)
                    executed.append(tc)
        except Exception:  # noqa: BLE001
            db.rollback()

    return client_tools, executed
