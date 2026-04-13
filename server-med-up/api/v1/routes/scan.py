from fastapi import APIRouter

from schemas.scan import ScanResult
from services.scan_service import extract_prescription

router = APIRouter(prefix="/scan", tags=["scan"])


@router.post("/prescription", response_model=ScanResult)
async def scan_prescription(image_base64: str = ""):
    result = await extract_prescription(image_base64)
    return ScanResult(**result)
