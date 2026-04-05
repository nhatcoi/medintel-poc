from uuid import UUID

from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from ai.ocr import extract_prescription
from app.api.deps import DbSession
from app.core.config import settings
from app.repositories.profile_repository import get_by_id
from app.schemas.scan import ScanPersistedResponse, ScanResult
from app.services.prescription_scan_service import normalize_llm_scan_dict, persist_scan_result

router = APIRouter()

ALLOWED_MIME = {"image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"}


def _resolve_user_id(user_id: str | None) -> UUID:
    raw = (user_id or "").strip()
    if raw:
        try:
            return UUID(raw)
        except ValueError as exc:
            raise HTTPException(status_code=400, detail="user_id phải là UUID hợp lệ") from exc

    fallback = (settings.default_prescription_user_id or "").strip()
    if fallback:
        try:
            return UUID(fallback)
        except ValueError as exc:
            raise HTTPException(
                status_code=500,
                detail="DEFAULT_PRESCRIPTION_USER_ID trong .env không phải UUID hợp lệ",
            ) from exc

    raise HTTPException(
        status_code=400,
        detail="Thiếu user_id (multipart form) hoặc DEFAULT_PRESCRIPTION_USER_ID trong .env",
    )


@router.post("/prescription", response_model=ScanPersistedResponse)
async def scan_prescription(
    db: DbSession,
    file: UploadFile = File(...),
    user_id: str | None = Form(None),
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
            detail="Chưa cấu hình LLM_API_KEY trong .env (server-med). Thêm key rồi khởi động lại uvicorn.",
        )

    uid = _resolve_user_id(user_id)
    user = get_by_id(db, uid)
    if user is None:
        raise HTTPException(status_code=404, detail="Không tìm thấy user")

    try:
        raw_llm = await extract_prescription(image_bytes, mime_type=mime)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"AI scan error: {exc}") from exc

    normalized = normalize_llm_scan_dict(raw_llm)
    try:
        scan = ScanResult.model_validate(normalized)
    except Exception as exc:
        raise HTTPException(status_code=422, detail=f"Dữ liệu AI không hợp lệ: {exc}") from exc

    try:
        prescription_id, saved = persist_scan_result(db, profile_id=uid, scan=scan)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Lưu DB thất bại: {exc}") from exc

    payload = {
        **scan.model_dump(),
        "prescription_id": str(prescription_id),
        "saved_medications": [m.model_dump() for m in saved],
    }
    return ScanPersistedResponse.model_validate(payload)
