from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from api.deps import get_db
from services.reminder_service import process_missed_medications

router = APIRouter()


@router.post("/trigger-checks")
def trigger_reminder_checks(db: Session = Depends(get_db)):
    """
    Manually triggers the background sweep for missed medications.
    """
    result = process_missed_medications(db)
    return {"status": "ok", "detail": result}
