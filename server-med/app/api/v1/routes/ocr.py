from fastapi import APIRouter, HTTPException, UploadFile

from ai.ocr import extract_prescription

router = APIRouter()


@router.post("/extract")
async def ocr_extract(file: UploadFile):
    mime = (file.content_type or "").lower()
    if not mime.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    image_bytes = await file.read()
    try:
        result = await extract_prescription(image_bytes, mime_type=mime)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"OCR error: {exc}")
    return result
