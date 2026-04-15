import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Query
from sqlalchemy import select

from api.deps import DbSession
from models.reporting import Notification
from schemas.notifications import NotificationCreate, NotificationListResponse, NotificationRead, NotificationUpdate

router = APIRouter(prefix="/notifications", tags=["notifications"])


def _uuid(raw: str, detail: str = "Invalid UUID") -> uuid.UUID:
    try:
        return uuid.UUID(raw.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=detail) from exc


def _to_read(n: Notification) -> NotificationRead:
    return NotificationRead(
        notification_id=str(n.id),
        profile_id=str(n.profile_id),
        notification_type=n.notification_type,
        title=n.title,
        message=n.message,
        related_id=str(n.related_id) if n.related_id else None,
        is_read=n.is_read,
        read_at=n.read_at,
        scheduled_for=n.scheduled_for,
        sent_at=n.sent_at,
    )


@router.get("/", response_model=NotificationListResponse)
def list_notifications(db: DbSession, profile_id: str = Query(...), unread_only: bool = Query(False)):
    stmt = select(Notification).where(Notification.profile_id == _uuid(profile_id, "Invalid profile_id"))
    if unread_only:
        stmt = stmt.where(Notification.is_read.is_(False))
    rows = db.scalars(stmt.order_by(Notification.created_at.desc())).all()
    return NotificationListResponse(items=[_to_read(n) for n in rows])


@router.post("/", response_model=NotificationRead)
def create_notification(body: NotificationCreate, db: DbSession):
    row = Notification(
        profile_id=_uuid(body.profile_id, "Invalid profile_id"),
        notification_type=body.notification_type,
        title=body.title,
        message=body.message,
        related_id=_uuid(body.related_id, "Invalid related_id") if body.related_id else None,
        scheduled_for=body.scheduled_for,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return _to_read(row)


@router.patch("/{notification_id}", response_model=NotificationRead)
def update_notification(notification_id: str, body: NotificationUpdate, db: DbSession):
    row = db.get(Notification, _uuid(notification_id, "Invalid notification_id"))
    if row is None:
        raise HTTPException(status_code=404, detail="Notification not found")
    for key in ("notification_type", "title", "message", "is_read", "scheduled_for", "sent_at"):
        value = getattr(body, key)
        if value is not None:
            setattr(row, key, value)
    if body.read_at is not None:
        row.read_at = body.read_at
    elif body.is_read is True and row.read_at is None:
        row.read_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(row)
    return _to_read(row)


@router.delete("/{notification_id}")
def delete_notification(notification_id: str, db: DbSession):
    row = db.get(Notification, _uuid(notification_id, "Invalid notification_id"))
    if row is None:
        raise HTTPException(status_code=404, detail="Notification not found")
    db.delete(row)
    db.commit()
    return {"ok": True, "notification_id": notification_id}

