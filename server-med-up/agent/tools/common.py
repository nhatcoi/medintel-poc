from __future__ import annotations

import json
import uuid
from datetime import datetime, time


def tool_ok(summary: str, data_ref: str | None = None, extra: dict | None = None) -> str:
    payload = {"status": "ok", "summary": summary, "data_ref": data_ref}
    if extra:
        payload["extra"] = extra
    return json.dumps(payload, ensure_ascii=False)


def tool_error(summary: str, code: str = "TOOL_ERROR") -> str:
    return json.dumps({"status": "error", "code": code, "summary": summary}, ensure_ascii=False)


def tool_confirm_required(summary: str, action: str, proposed_args: dict | None = None) -> str:
    return json.dumps(
        {
            "status": "confirm_required",
            "code": "WRITE_CONFIRM_REQUIRED",
            "summary": summary,
            "action": action,
            "proposed_args": proposed_args or {},
        },
        ensure_ascii=False,
    )


def parse_uuid(value: str | None) -> uuid.UUID | None:
    if not value:
        return None
    try:
        return uuid.UUID(str(value).strip())
    except Exception:
        return None


def parse_time_hhmm(raw: str | None) -> time | None:
    if not raw:
        return None
    token = str(raw).strip().lower().replace("h", ":")
    if token.endswith(":"):
        token += "00"
    if ":" not in token:
        return None
    try:
        hh, mm = token.split(":", 1)
        return time(hour=max(0, min(23, int(hh))), minute=max(0, min(59, int(mm))))
    except Exception:
        return None


def now_iso() -> str:
    return datetime.now().astimezone().isoformat()

