from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from core.config import settings
from schemas.scan import ScanResult
from services.scan_service import extract_prescription

router = APIRouter(prefix="/scan", tags=["scan"])

ALLOWED_MIME = {"image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"}


@router.post("/prescription", response_model=ScanResult)
async def scan_prescription(
    file: UploadFile = File(...),
    user_id: str | None = Form(None),  # kept for client compatibility
):
    del user_id
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
    return ScanResult(**result)
