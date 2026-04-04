"""OCR đơn thuốc bằng AI Vision — gửi ảnh đến LLM endpoint, trả về structured JSON."""

from __future__ import annotations

import base64
import json
import re

import httpx

from app.core.config import settings

EXTRACT_PROMPT = """Bạn là một chuyên gia y tế. Hãy phân tích ảnh đơn thuốc/toa thuốc này và trích xuất thông tin.

QUAN TRỌNG: CHỈ trả về JSON hợp lệ, KHÔNG có markdown ```json ... ```, KHÔNG có văn bản giải thích. 
Đảm bảo tất cả chuỗi được đóng mở dấu ngoặc kép đúng cách. Cấu trúc JSON:
{
  "doctor_name": "tên bác sĩ (nếu có)",
  "issued_date": "YYYY-MM-DD (nếu có)",
  "patient_name": "tên bệnh nhân (nếu có)",
  "raw_text": "toàn bộ text đọc được từ ảnh",
  "medications": [
    {
      "name": "tên thuốc",
      "dosage": "liều dùng (vd: 500mg)",
      "frequency": "tần suất (vd: 2 lần/ngày)",
      "instructions": "hướng dẫn (vd: uống sau ăn)",
      "times": ["08:00", "20:00"]
    }
  ]
}

Lưu ý:
- Nếu không đọc được trường nào, để null
- "times" là mảng giờ uống thuốc dạng HH:MM (24h), suy luận từ frequency
- Nếu frequency là "3 lần/ngày" -> times: ["07:00", "13:00", "19:00"]
- Nếu frequency là "2 lần/ngày" -> times: ["08:00", "20:00"]
- Nếu frequency là "1 lần/ngày" -> times: ["08:00"]
- Nếu không rõ -> times: ["08:00"]
"""


async def extract_prescription(image_bytes: bytes, mime_type: str = "image/jpeg") -> dict:
    """Gửi ảnh đơn thuốc đến AI Vision, trả về dict đã parse."""
    b64 = base64.b64encode(image_bytes).decode("utf-8")

    payload = {
        "model": settings.llm_model,
        "stream": False,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": EXTRACT_PROMPT},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:{mime_type};base64,{b64}",
                        },
                    },
                ],
            }
        ],
        "max_tokens": 2048,
    }

    async with httpx.AsyncClient(timeout=90) as client:
        try:
            resp = await client.post(
                settings.llm_base_url,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {settings.llm_api_key}",
                },
                json=payload,
            )
        except httpx.RequestError as exc:
            raise RuntimeError(
                f"Không kết nối được LLM ({settings.llm_base_url}): {exc}"
            ) from exc

    if resp.status_code != 200:
        snippet = (resp.text or "").replace("\n", " ").strip()[:500]
        raise RuntimeError(f"LLM HTTP {resp.status_code}: {snippet or '(empty body)'}")

    try:
        data = resp.json()
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"LLM trả về không phải JSON: {(resp.text or '')[:200]}") from exc

    choices = data.get("choices", [])
    if not choices:
        raise ValueError("AI không trả về kết quả.")

    raw_content = choices[0].get("message", {}).get("content", "").strip()

    # Find the FIRST { and the LAST } to extract a clean JSON block
    start_idx = raw_content.find("{")
    end_idx = raw_content.rfind("}")
    
    if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
        json_str = raw_content[start_idx:end_idx+1]
    else:
        json_str = raw_content

    try:
        return json.loads(json_str)
    except json.JSONDecodeError as e:
        # Log raw content for debugging
        print(f"JSON parse error at char {e.pos}: {e.msg}")
        print(f"Raw LLM content (first 500 chars): {raw_content[:500]!r}")
        print(f"Extracted JSON (first 500 chars): {json_str[:500]!r}")
        
        # Attempt to fix common JSON issues
        cleaned = json_str
        
        # Remove markdown code blocks
        cleaned = re.sub(r"```(?:json)?\s*", "", cleaned)
        cleaned = re.sub(r"\s*```", "", cleaned)
        
        # Fix trailing commas
        cleaned = re.sub(r",\s*([}\]])", r"\1", cleaned)
        
        # Try to fix unterminated strings and missing quotes
        # Look for patterns like: "key": value without quotes, or unterminated strings
        
        # Fix missing closing quotes - look for quote followed by comma/brace without closing quote
        # Pattern: "text, "next" -> "text", "next"
        cleaned = re.sub(r'([^"\\])"([^"]*),\s*"', r'\1"\2", "', cleaned)
        
        # Fix values without quotes (but not null/true/false/numbers)
        # Pattern: "key": unquoted_value -> "key": "unquoted_value"
        def fix_unquoted_values(match):
            key_part = match.group(1)
            value = match.group(2).strip()
            
            # Don't quote null, booleans, numbers, or already quoted strings
            if value in ('null', 'true', 'false') or value.startswith('"') or value.startswith('[') or value.startswith('{'):
                return match.group(0)
            
            # Try to parse as number
            try:
                float(value.rstrip(','))
                return match.group(0)
            except ValueError:
                pass
            
            # Add quotes around the value
            if value.endswith(','):
                return f'{key_part}"{value[:-1]}",'
            else:
                return f'{key_part}"{value}"'
        
        cleaned = re.sub(r'("[^"]*":\s*)([^",\[\]{}]+)', fix_unquoted_values, cleaned)
        
        try:
            return json.loads(cleaned)
        except json.JSONDecodeError as e2:
            # If still fails, return a minimal valid structure
            print(f"Final JSON fix attempt failed: {e2}")
            return {
                "doctor_name": None,
                "issued_date": None,
                "patient_name": None,
                "raw_text": f"JSON parse error: {raw_content[:200]}...",
                "medications": []
            }
