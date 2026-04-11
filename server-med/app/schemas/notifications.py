"""Schema: notifications."""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class NotificationCreate(BaseModel):
    profile_id: uuid.UUID
    notification_type: str
    title: str
    message: str
    related_id: uuid.UUID | None = None
    scheduled_for: datetime | None = None


class NotificationRead(BaseModel):
    notification_id: uuid.UUID
    profile_id: uuid.UUID
    notification_type: str
    title: str
    message: str
    related_id: uuid.UUID | None = None
    is_read: bool = False
    read_at: datetime | None = None
    scheduled_for: datetime | None = None
    sent_at: datetime | None = None
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


class NotificationListResponse(BaseModel):
    profile_id: uuid.UUID
    unread_count: int = 0
    items: list[NotificationRead] = Field(default_factory=list)
