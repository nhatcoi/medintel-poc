from __future__ import annotations

import uuid
from typing import Sequence

from sqlalchemy import select
from sqlalchemy.orm import Session

from models.reporting import Notification
from schemas.notifications import NotificationCreate


class NotificationRepository:
    def __init__(self, db: Session):
        self.db = db

    def create(self, obj_in: NotificationCreate) -> Notification:
        db_obj = Notification(
            profile_id=uuid.UUID(obj_in.profile_id),
            notification_type=obj_in.notification_type,
            title=obj_in.title,
            message=obj_in.message,
            related_id=uuid.UUID(obj_in.related_id) if obj_in.related_id else None,
            scheduled_for=obj_in.scheduled_for,
        )
        self.db.add(db_obj)
        self.db.commit()
        self.db.refresh(db_obj)
        return db_obj

    def bulk_create(self, objs_in: list[NotificationCreate]) -> list[Notification]:
        db_objs = [
            Notification(
                profile_id=uuid.UUID(obj.profile_id),
                notification_type=obj.notification_type,
                title=obj.title,
                message=obj.message,
                related_id=uuid.UUID(obj.related_id) if obj.related_id else None,
                scheduled_for=obj.scheduled_for,
            )
            for obj in objs_in
        ]
        self.db.add_all(db_objs)
        self.db.commit()
        for idx in range(len(db_objs)):
            self.db.refresh(db_objs[idx])
        return db_objs

    def get_by_profile(self, profile_id: uuid.UUID) -> Sequence[Notification]:
        stmt = (
            select(Notification)
            .where(Notification.profile_id == profile_id)
            .order_by(Notification.created_at.desc())
        )
        return self.db.scalars(stmt).all()
