import uuid
from datetime import date, time

from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from api.deps import DbSession
from core.config import settings
from repositories import medication_repo
from schemas.scan import ScanResult
from services.scan_service import extract_prescription

router = APIRouter(prefix="/scan", tags=["scan"])

ALLOWED_MIME = {"image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"}


@router.post("/prescription", response_model=ScanResult)
async def scan_prescription(
    db: DbSession,
    file: UploadFile = File(...),
    profile_id: str | None = Form(None),
    user_id: str | None = Form(None),  # legacy compatibility from client
    persist: bool = Form(True),
):
    mime = (file.content_type or "").lower()
    if mime not in ALLOWED_MIME:
        raise HTTPException(status_code=400, detail=f"Unsupported image type: {mime}")

    image_bytes = await file.read()
    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="Image too large (max 10MB)")

    if not (settings.llm_api_key or "").strip():
        raise HTTPException(
            status_code=503,
            detail="Missing LLM_API_KEY/GROQ_API_KEY in server-med-up .env",
        )

    result = await extract_prescription(image_bytes, mime_type=mime)
    if not persist:
        return ScanResult(**result)

    resolved_profile_id = (
        (profile_id or "").strip()
        or (user_id or "").strip()
        or (settings.default_prescription_user_id or "").strip()
    )
    if not resolved_profile_id:
        return ScanResult(**result)

    try:
        pid = uuid.UUID(resolved_profile_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid profile_id/user_id UUID") from exc

    period_id = medication_repo.ensure_latest_period_id_by_profile(db, pid)

    parsed_prescription_date: date | None = None
    raw_prescription_date = result.get("prescription_date")
    if isinstance(raw_prescription_date, str) and raw_prescription_date.strip():
        try:
            parsed_prescription_date = date.fromisoformat(raw_prescription_date.strip()[:10])
        except ValueError:
            parsed_prescription_date = None

    saved: list[dict] = []
    for med in result.get("medications", []):
        name = str(med.get("medication_name") or "").strip()
        if not name:
            continue
        created = medication_repo.create_medication(
            db,
            period_id=period_id,
            medication_name=name,
            dosage=med.get("dosage"),
            frequency=med.get("frequency"),
            instructions=med.get("instructions"),
            start_date=parsed_prescription_date or date.today(),
            notes=f"Created from OCR scan ({file.filename or 'prescription image'})",
        )

        times = med.get("times") or ["08:00"]
        for tstr in times:
            tval = str(tstr).strip().replace(".", ":")
            try:
                hh, mm = tval.split(":", 1)
                scheduled = time(hour=max(0, min(23, int(hh))), minute=max(0, min(59, int(mm))))
            except Exception:
                scheduled = time(hour=8, minute=0)
            medication_repo.create_schedule(db, medication_id=created.id, scheduled_time=scheduled)

        saved.append({"id": str(created.id), "name": created.medication_name})

    result["prescription_id"] = str(period_id)
    result["saved_medications"] = saved
    return ScanResult(**result)
