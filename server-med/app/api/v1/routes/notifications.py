"""CRUD thông báo."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, HTTPException, Query
from sqlalchemy import func, select

from app.api.deps import DbSession
from app.models.mixins import utc_now
from app.models.reporting import Notification
from app.schemas.notifications import NotificationCreate, NotificationListResponse, NotificationRead

router = APIRouter()


@router.get("", response_model=NotificationListResponse)
def list_notifications(
    db: DbSession,
    profile_id: uuid.UUID = Query(...),
    unread_only: bool = Query(False),
    limit: int = Query(50, le=200),
):
    q = select(Notification).where(Notification.profile_id == profile_id)
    if unread_only:
        q = q.where(Notification.is_read == False)  # noqa: E712
    rows = db.scalars(q.order_by(Notification.created_at.desc()).limit(limit)).all()

    unread_count = db.scalar(
        select(func.count())
        .select_from(Notification)
        .where(Notification.profile_id == profile_id, Notification.is_read == False)  # noqa: E712
    ) or 0

    items = [
        NotificationRead(
            notification_id=n.id,
            profile_id=n.profile_id,
            notification_type=n.notification_type,
            title=n.title,
            message=n.message,
            related_id=n.related_id,
            is_read=n.is_read,
            read_at=n.read_at,
            scheduled_for=n.scheduled_for,
            sent_at=n.sent_at,
            created_at=n.created_at,
        )
        for n in rows
    ]
    return NotificationListResponse(profile_id=profile_id, unread_count=unread_count, items=items)


@router.post("", response_model=NotificationRead, status_code=201)
def create_notification(body: NotificationCreate, db: DbSession):
    notif = Notification(
        profile_id=body.profile_id,
        notification_type=body.notification_type,
        title=body.title,
        message=body.message,
        related_id=body.related_id,
        scheduled_for=body.scheduled_for,
    )
    db.add(notif)
    db.commit()
    db.refresh(notif)
    return NotificationRead(
        notification_id=notif.id,
        profile_id=notif.profile_id,
        notification_type=notif.notification_type,
        title=notif.title,
        message=notif.message,
        related_id=notif.related_id,
        is_read=notif.is_read,
        read_at=notif.read_at,
        scheduled_for=notif.scheduled_for,
        sent_at=notif.sent_at,
        created_at=notif.created_at,
    )


@router.patch("/{notification_id}/read")
def mark_read(notification_id: uuid.UUID, db: DbSession):
    notif = db.get(Notification, notification_id)
    if not notif:
        raise HTTPException(404, "Không tìm thấy thông báo")
    notif.is_read = True
    notif.read_at = utc_now()
    db.commit()
    return {"ok": True}


@router.post("/mark-all-read")
def mark_all_read(db: DbSession, profile_id: uuid.UUID = Query(...)):
    now = utc_now()
    db.execute(
        Notification.__table__
        .update()
        .where(Notification.profile_id == profile_id, Notification.is_read == False)  # noqa: E712
        .values(is_read=True, read_at=now)
    )
    db.commit()
    return {"ok": True}


@router.delete("/{notification_id}", status_code=204)
def delete_notification(notification_id: uuid.UUID, db: DbSession):
    notif = db.get(Notification, notification_id)
    if not notif:
        raise HTTPException(404, "Không tìm thấy thông báo")
    db.delete(notif)
    db.commit()
