---
name: agentic-medical-adherence
description: >-
  MedIntel: danh mục tính năng app + chat agentic tuân thủ điều trị (tool_calls, RAG/pgvector,
  intent bệnh nhân). Dùng khi thiết kế prompt/API, orchestration, hoặc khi user nhắc
  agentic-medical.md, medication adherence, drug interaction, OCR đơn, server-med chat.
---

# MedIntel — Tính năng ứng dụng & agentic tuân thủ điều trị

## Nguồn trong repo

| File / thư mục | Vai trò |
|----------------|---------|
| **`agentic-medical.md`** | Ý tưởng chi tiết: 6 nhóm intent, flow mẫu, micro-agent, tool gợi ý, pattern ReAct/graph, tính năng AI bổ sung |
| **`doc.md`** | Stack & module MedIntel (Flutter features, FastAPI, DB, OCR/LLM/RAG đề xuất) |
| **`db-design.md`** | Schema local-first / sync (nếu có) |
| **`architecture.md`** | Kiến trúc 3 lớp, Postgres/pgvector |
| **`server-med/ai/chatbot/__init__.py`** | System prompt + **tool_calls** thực tế đang cho phép |
| **`server-med/app/api/v1/routes/`** | API: `chat`, `scan`, `auth`, `ocr`, `health` |
| **`tools/crawl/`** | Script mẫu `crawl_thuocbietduoc_sample.py` (JSON); không còn import DAV → Postgres |

Báo cáo NCKH / COM-B / Thông tư 26: dùng thêm **`/medintel-nckh`**.

---

## 1. Tính năng ứng dụng MedIntel (đặc tả theo `doc.md`)

Gom theo **mobile (Flutter)** và **hạ tầng**; một số màn hình có thể đang prototype.

### 1.1 Mobile — module & trải nghiệm

| Nhóm | Tính năng (mô tả ngắn) |
|------|-------------------------|
| **Onboarding** | Làm quen app, (tuỳ thiết kế) thiết lập hồ sơ ban đầu |
| **Auth** | Đăng nhập; token JWT giao tiếp API (`server-med` có route auth) |
| **Home / Dashboard** | Tổng quan ngày, lối tắt tới thuốc, chat, tuân thủ |
| **prescription_scan** | Chụp/quét ảnh đơn thuốc → OCR (+ LLM structured) → chuẩn hoá đơn |
| **medication** | Danh sách thuốc, chi tiết, liều / gợi ý lịch (theo đặc tả) |
| **reminder** | Nhắc uống thuốc (local notification; FCM đề xuất trong doc) |
| **adherence** | Theo dõi đã uống / quên / bỏ liều; dashboard tuân thủ |
| **ai_chat** | Chat hỗ trợ tuân thủ; nhận `tool_calls` + `suggested_actions` từ server để app thực thi cục bộ |

### 1.2 Backend & dữ liệu

| Thành phần | Tính năng |
|------------|-----------|
| **FastAPI** | REST: người dùng/hồ sơ, xử lý đơn, lịch, tích hợp AI (theo doc) |
| **PostgreSQL** | Người dùng, đơn, thuốc, lịch, log tuân thủ, lịch sử chat (mô hình trong doc; bảng cụ thể theo migration thực tế) |
| **JWT** | Xác thực API |
| **OCR + LLM** | Pipeline quét đơn (route scan: ảnh → trích xuất có cấu trúc) |
| **RAG / pgvector** | Đề xuất trong doc; module `server-med/ai/rag/` hiện placeholder — chưa truy vấn vector trong code mẫu |
| **Lưu trữ ảnh** | R2 / S3 (doc) |

### 1.3 Dữ liệu tham chiếu thuốc (roadmap)

Catalog DAV đã gỡ khỏi repo/ORM; RAG hoặc tra cứu sau này cần nguồn và pipeline riêng (tài liệu chunk, API chính thức, v.v.).

---

## 2. Tính năng “agentic” — gọi AI & công cụ

### 2.1 Luồng chat hiện có (`POST` chat /message)

1. Client gửi nội dung người dùng (+ tuỳ chọn `profile_id` để **lưu phiên** vào DB).
2. Server gọi LLM OpenAPI-compatible với **system prompt** định nghĩa MedIntel Agent.
3. LLM trả **một JSON**: `reply`, `tool_calls`, `suggested_actions`.
4. **`tool_calls`**: server **chỉ chuẩn hoá và trả về** cho client — **thực thi lưu dữ liệu do app cục bộ** (local-first trong prompt).
5. **`suggested_actions`**: chip gợi ý câu tiếp theo (UI).

### 2.2 Tool calls được phép (whitelist trong code)

Định nghĩa trong `server-med/ai/chatbot/__init__.py` — `ALLOWED_TOOLS`:

| Tool | Mục đích agentic | Tham số chính (tóm tắt) |
|------|------------------|-------------------------|
| **`log_dose`** | Ghi nhận một liều (tuân thủ) | `medication_name`, `status`: taken / missed / skipped, `note?`, `recorded_at?` |
| **`upsert_medication`** | Thêm/cập nhật thuốc trong danh sách cục bộ | `name`, `dosage_label?`, `schedule_hint?` |
| **`append_care_note`** | Nhật ký / ghi chú nhanh | `text` |
| **`save_reminder_intent`** | Nháp ý định nhắc (báo thức thật do app xử lý) | `title`, `detail?` |

**Chưa có trong whitelist:** `get_patient_medications`, `get_today_schedule`, `check_drug_interaction`, `search_drug_knowledge`, v.v. — các tool đó nằm trong **`agentic-medical.md`** như **mục tiêu kiến trúc**; khi triển khai cần mở rộng `ALLOWED_TOOLS` + thực thi server hoặc client.

### 2.3 OCR đơn thuốc (AI pipeline, không phải chat tool)

- Route **scan prescription**: ảnh → LLM/OCR → chuẩn hoá → có thể **persist** qua service (xem `scan.py`, `prescription_scan_service`).
- Bổ trợ **nhập liệu** và giảm sai sót — trục agentic “tuân thủ” thường kết hợp: quét đơn → danh sách thuốc trên máy → chat `log_dose` / lịch.

### 2.4 RAG (roadmap)

- `agentic-medical.md` + `doc.md`: RAG trên drug DB + **pgvector**.
- Code: `ai/rag/` — cần implement `answer_with_context` và nối vào chat nếu muốn trả lời có trích dẫn từ kho tài liệu đã chunk (hoặc nguồn khác).

---

## 3. Bản đồ `agentic-medical.md` → hệ thống

### 3.1 Sáu nhóm intent bệnh nhân (tài liệu thiết kế)

| # | Intent | Agent / tool (trong tài liệu) | Ghi chú đối chiếu MedIntel code |
|---|--------|-------------------------------|----------------------------------|
| 1 | Uống / ghi nhận thuốc | `get_patient_medications` → hỏi chọn → `log_medication` | Có **`log_dose`**; chưa có tool “lấy danh sách” từ server trong whitelist |
| 2 | Lịch hôm nay | `get_today_schedule`, `check_taken_status` | Roadmap — cần API + tool |
| 3 | Quên / uống muộn | guideline + khoảng cách liều | Prompt an toàn + (sau) tool lịch/log |
| 4 | Tác dụng phụ | `check_side_effects` | Roadmap — thường cần RAG + nguồn chuyên môn |
| 5 | Tương tác thuốc | `check_drug_interaction` | Roadmap — DB interaction hoặc API ngoài |
| 6 | Kiến thức thuốc | `get_drug_info`, `search_drug_knowledge` | Roadmap — RAG + nguồn tham chiếu đáng tin cậy |

### 3.2 Micro-agent (khái niệm trong `agentic-medical.md`)

Chat Agent điều phối (trong tài liệu): **Medication**, **Schedule**, **Drug Knowledge**, **Side Effect**, **Drug Interaction**, **Adherence**.  
Thực tế triển khai có thể: **một LLM + nhiều tool** hoặc **LangGraph / multi-agent** — skill **`/medintel-architecture`** bổ sung chi tiết stack.

### 3.3 Tính năng AI bổ sung (mục tiêu sản phẩm — `agentic-medical.md`)

- Missed medication detection (cron/push).
- Symptom monitoring / triage (nhẹ–nặng).
- Adherence score tuần.
- Proactive agent (hỏi “đã uống chưa?”).

---

## 4. Quy tắc cho agent (Claude) khi viết / thiết kế

1. **Phân tách:** tool **đã có trong `ALLOWED_TOOLS`** vs tool chỉ trong **tài liệu** — không mô tả nhầm đã production.  
2. **An toàn:** không chẩn đoán, không thay bác sĩ, không đổi liều; triệu chứng nặng → hướng dẫn cấp cứu / BS.  
3. **Nguồn sự thật:** tra cứu thuốc cần nguồn chuyên môn / tài liệu được phép dùng + RAG nếu có; tránh bịa.  
4. **Output có cấu trúc:** giữ khớp schema JSON (`reply`, `tool_calls`, `suggested_actions`) khi sửa `chatbot`.  
5. **Mở rộng tool:** mỗi tool mới → cập nhật `ALLOWED_TOOLS`, system prompt, và (nếu server-side) repository + route.

## Lệnh skill liên quan

- **`/medintel-nckh`** — báo cáo, COM-B, PDF đề tài  
- **`/medintel-architecture`** — sơ đồ 3 lớp, Postgres/pgvector  
- **`/medintel-db-local-sync`** — schema local/sync  
- **`/nckh-bao-cao`**, **`/tai-lieu-tham-khao`** — viết báo cáo & tham khảo  
