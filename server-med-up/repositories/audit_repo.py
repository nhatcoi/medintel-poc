from __future__ import annotations

import uuid
from typing import Any

from sqlalchemy.orm import Session

from models.audit import AuditLog


def log_action(
    db: Session,
    *,
    actor_profile_id: uuid.UUID | None = None,
    action_type: str,
    table_name: str | None = None,
    record_id: uuid.UUID | None = None,
    old_value: dict[str, Any] | None = None,
    new_value: dict[str, Any] | None = None,
    ip_address: str | None = None,
    user_agent: str | None = None,
) -> AuditLog:
    entry = AuditLog(
        actor_profile_id=actor_profile_id,
        action_type=action_type,
        table_name=table_name,
        record_id=record_id,
        old_value=old_value,
        new_value=new_value,
        ip_address=ip_address,
        user_agent=user_agent,
    )
    db.add(entry)
    db.flush()
    return entry
