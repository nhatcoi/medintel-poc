"""Prescription scan OCR via OpenAI-compatible vision endpoint."""

from __future__ import annotations

import base64
import json
import re

import httpx

from core.config import settings

_EXTRACT_PROMPT = """Bạn là chuyên gia đọc đơn thuốc tiếng Việt.
Trích xuất thông tin từ ảnh đơn thuốc và CHỈ trả về JSON hợp lệ (không markdown).

Schema bắt buộc:
{
  "disease_name": "chẩn đoán/bệnh nếu có, không có thì để rỗng",
  "prescribing_doctor": "tên bác sĩ nếu có",
  "prescription_date": "YYYY-MM-DD nếu có",
  "medications": [
    {
      "medication_name": "tên thuốc",
      "dosage": "liều dùng",
      "frequency": "tần suất",
      "instructions": "cách dùng",
      "times": ["08:00", "20:00"]
    }
  ]
}

Quy tắc:
- Nếu không chắc trường nào thì để null hoặc chuỗi rỗng.
- `times` luôn là mảng giờ HH:MM 24h.
- Nếu không có giờ rõ ràng, suy luận từ frequency:
  - 1 lần/ngày -> ["08:00"]
  - 2 lần/ngày -> ["08:00","20:00"]
  - 3 lần/ngày -> ["07:00","13:00","19:00"]
  - không rõ -> ["08:00"]
"""


def _safe_json_load(raw_content: str) -> dict:
    start_idx = raw_content.find("{")
    end_idx = raw_content.rfind("}")
    if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
        candidate = raw_content[start_idx : end_idx + 1]
    else:
        candidate = raw_content

    try:
        parsed = json.loads(candidate)
        return parsed if isinstance(parsed, dict) else {}
    except json.JSONDecodeError:
        cleaned = re.sub(r"```(?:json)?\s*", "", candidate)
        cleaned = re.sub(r"\s*```", "", cleaned)
        cleaned = re.sub(r",\s*([}\]])", r"\1", cleaned)
        try:
            parsed = json.loads(cleaned)
            return parsed if isinstance(parsed, dict) else {}
        except json.JSONDecodeError:
            return {}


def _normalize_medications(items: object) -> list[dict]:
    if not isinstance(items, list):
        return []

    out: list[dict] = []
    for item in items:
        if not isinstance(item, dict):
            continue
        name = (
            str(item.get("medication_name") or item.get("name") or "")
            .strip()
        )
        if not name:
            continue
        times = item.get("times")
        if not isinstance(times, list) or not times:
            times = ["08:00"]
        times = [str(t) for t in times if t is not None]
        out.append(
            {
                "medication_name": name,
                "dosage": item.get("dosage"),
                "frequency": item.get("frequency"),
                "instructions": item.get("instructions"),
                "times": times or ["08:00"],
            }
        )
    return out


async def extract_prescription(image_bytes: bytes, mime_type: str = "image/jpeg") -> dict:
    """Extract structured prescription data from image bytes."""
    image_b64 = base64.b64encode(image_bytes).decode("utf-8")
    model_name = (settings.llm_vision_model or settings.llm_model).strip()

    payload = {
        "model": model_name,
        "stream": False,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": _EXTRACT_PROMPT},
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:{mime_type};base64,{image_b64}"},
                    },
                ],
            }
        ],
        "temperature": 0,
        "max_tokens": 2048,
    }

    endpoint = f"{settings.llm_base_url.rstrip('/')}/chat/completions"
    async with httpx.AsyncClient(timeout=90) as client:
        try:
            response = await client.post(
                endpoint,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {settings.llm_api_key}",
                },
                json=payload,
            )
        except httpx.RequestError as exc:
            raise RuntimeError(f"Cannot reach vision LLM endpoint: {exc}") from exc

    if response.status_code != 200:
        snippet = (response.text or "").replace("\n", " ").strip()[:500]
        raise RuntimeError(f"Vision LLM HTTP {response.status_code}: {snippet or '(empty)'}")

    data = response.json()
    choices = data.get("choices") or []
    if not choices:
        return {"disease_name": "", "prescribing_doctor": None, "prescription_date": None, "medications": []}

    raw_content = str(choices[0].get("message", {}).get("content", "")).strip()
    parsed = _safe_json_load(raw_content)

    return {
        "disease_name": str(parsed.get("disease_name") or parsed.get("diagnosis") or "").strip(),
        "prescribing_doctor": parsed.get("prescribing_doctor") or parsed.get("doctor_name"),
        "prescription_date": parsed.get("prescription_date") or parsed.get("issued_date"),
        "medications": _normalize_medications(parsed.get("medications")),
    }
