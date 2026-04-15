from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class NotificationCreate(BaseModel):
    profile_id: str
    notification_type: str
    title: str
    message: str
    related_id: str | None = None
    scheduled_for: datetime | None = None


class NotificationUpdate(BaseModel):
    notification_type: str | None = None
    title: str | None = None
    message: str | None = None
    is_read: bool | None = None
    read_at: datetime | None = None
    scheduled_for: datetime | None = None
    sent_at: datetime | None = None


class NotificationRead(BaseModel):
    notification_id: str
    profile_id: str
    notification_type: str
    title: str
    message: str
    related_id: str | None = None
    is_read: bool
    read_at: datetime | None = None
    scheduled_for: datetime | None = None
    sent_at: datetime | None = None


class NotificationListResponse(BaseModel):
    items: list[NotificationRead] = Field(default_factory=list)

