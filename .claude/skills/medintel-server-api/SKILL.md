---
name: medintel-server-api
description: >-
  Backend FastAPI MedIntel: cấu trúc thư mục, API chat/agent/treatment, whitelist tool_calls,
  repository thuốc. Dùng khi sửa server-med, thêm tool agent, endpoint điều trị, hoặc đồng bộ Flutter.
---

# MedIntel — `server-med` API & lõi agent

## Cấu trúc (clean core)

| Khu vực | Đường dẫn | Vai trò |
|---------|-----------|---------|
| **Agent** | `app/services/agent/` | `registry.py` (ALLOWED_TOOLS), `tool_validation.py`, `medication_context.py` |
| **Chat** | `app/services/chat/` (pipeline, context, persistence, …) | Luồng LLM + lưu phiên; `preview_chat_message` (dry-run) |
| **LLM** | `ai/chatbot/prompts.py`, `ai/chatbot/llm_client.py` | System prompt + gọi API + parse JSON |
| **Thuốc** | `app/repositories/medication_repository.py` | Đọc `medications` theo `profile_id` (qua medical_records → treatment_periods) |
| **Schema** | `app/schemas/chat.py`, `treatment.py`, `agent_tools.py` | Pydantic request/response |

Mở rộng tool: sửa `ALLOWED_TOOLS` + `TOOL_DESCRIPTIONS` trong `registry.py`, cập nhật `build_system_prompt()` trong `ai/chatbot/prompts.py`, và (nếu cần) thực thi phía server sau này.

## REST (`/api/v1`)

| Method | Path | Mô tả |
|--------|------|--------|
| POST | `/chat/message` | Chat agentic; body: `text`, `profile_id?`, `session_id?`, **`include_medication_context`** |
| POST | `/chat/message/dry-run` | Giống trên, **không** ghi `chat_sessions` / `chat_messages` |
| GET | `/agent/tools` | Liệt kê tool + mô tả (OpenAPI-friendly) |
| POST | `/agent/tools/validate` | Chuẩn hoá `tool_calls` từ client; trả `dropped_count` |
| GET | `/treatment/medications` | `?profile_id=` — danh sách thuốc đã lưu từ đơn quét / điều trị |

Các route khác giữ nguyên: `/auth`, `/scan`, `/ocr`, `/health`.

## Hành vi `include_medication_context`

Khi `true` và `profile_id` hợp lệ: ghép khối “Thuốc đã lưu trên server” vào system prompt để LLM disambiguation tên thuốc (bổ trợ tool `log_dose` / hội thoại).

## Lệnh skill liên quan

- `/agentic-medical-adherence` — intent bệnh nhân & roadmap tool
- `/medintel-architecture` — kiến trúc tổng thể
- `/medintel-nckh` — đề tài & doc.md
