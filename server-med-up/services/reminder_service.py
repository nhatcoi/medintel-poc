from __future__ import annotations

import logging
from sqlalchemy.orm import Session

from models.medication import MedicationLog
from repositories.care_repo import CareRepository
from repositories.notification_repo import NotificationRepository
from models.base import utc_now
from schemas.notifications import NotificationCreate
from sqlalchemy import select

logger = logging.getLogger(__name__)


def process_missed_medications(db: Session) -> dict:
    """
    Scans for medications that are 'pending' but their scheduled_datetime has passed.
    Marks them as missed and creates notifications for the patient's care group members.
    """
    care_repo = CareRepository(db)
    notif_repo = NotificationRepository(db)
    
    now = utc_now()
    
    # 1. Find all pending medication logs that are past due, joining with medication and patient names
    from models.medication import Medication, MedicationSchedule
    from models.profile import Profile
    stmt = (
        select(MedicationLog, Medication.medication_name, Profile.full_name)
        .join(MedicationLog.schedule)
        .join(MedicationSchedule.medication)
        .join(Profile, Profile.id == MedicationLog.profile_id)
        .where(MedicationLog.scheduled_datetime <= now)
        .where(MedicationLog.status == "pending")
    )
    overdue_results = db.execute(stmt).all()
    
    if not overdue_results:
        return {"processed": 0, "notifications_sent": 0}
        
    notifications_to_create = []
    
    for log, med_name, patient_name in overdue_results:
        # Mark as missed
        log.status = "missed"
        
        # 2. Get all members across all care groups who have access to this patient
        members = care_repo.get_members_for_patient(patient_profile_id=log.profile_id)
        
        # Create notifications for all these members
        for member in members:
            if member.id == log.profile_id:
                continue
                
            notif = NotificationCreate(
                profile_id=str(member.id),
                notification_type="medication_missed",
                title=f"🚨 {patient_name} quên thuốc",
                message=f"Bệnh nhân {patient_name} chưa uống {med_name} vào lúc {log.scheduled_datetime.strftime('%H:%M')} ngày {log.scheduled_datetime.strftime('%d/%m')}.",
                related_id=str(log.id),
                scheduled_for=now
            )
            notifications_to_create.append(notif)
            
    # Save the log updates
    db.commit()
    
    # Send notifications in bulk
    if notifications_to_create:
        notif_repo.bulk_create(notifications_to_create)
        
    logger.info(f"Processed {len(overdue_results)} overdue logs, generated {len(notifications_to_create)} notifications.")
    return {
        "processed": len(overdue_results),
        "notifications_sent": len(notifications_to_create)
    }
