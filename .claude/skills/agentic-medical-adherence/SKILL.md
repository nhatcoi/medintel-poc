---
name: agentic-medical-adherence
description: >-
  Thiết kế chat AI tuân thủ điều trị theo workflow agentic: phân loại intent bệnh nhân,
  tool calling, RAG/pgvector, orchestration (ReAct, graph, planner). Dùng khi thiết kế
  prompt, API chat, tool schema, LangGraph/orchestrator, hoặc khi user nhắc agentic-medical.md,
  medication adherence agent, drug interaction, side effects, lịch uống thuốc.
---

# Agentic medical adherence (MedIntel)

## Nguồn mở rộng trong repo

Chi tiết ví dụ flow, bảng CSDL gợi ý và bảng so sánh framework: **`agentic-medical.md`**. Skill này tóm tắt phần agent cần nhớ khi code/prompt; đọc file trên khi cần case study đầy đủ.

Bối cảnh báo cáo / COM-B / pháp lý VN: kết hợp **`/medintel-nckh`** + `doc.md`.

## Ý tưởng cốt lõi

**Conversation-driven agentic:** mỗi tin nhắn bệnh nhân kích hoạt chuỗi *suy luận → (tuỳ chọn) gọi công cụ → quan sát kết quả → trả lời / hỏi làm rõ*. Không chỉ trả lời tĩnh: agent **lấy dữ liệu thật** (danh sách thuốc, lịch, log, knowledge base) rồi mới phản hồi.

Tách **Chat/orchestrator** khỏi **công cụ** (micro-agents hoặc function tools): schedule, drug info, side effects, interactions, adherence.

## Sáu nhóm intent thường gặp

| Nhóm | Ví dụ ý định người dùng | Công việc agent |
|------|-------------------------|-----------------|
| Ghi nhận uống thuốc | “Tôi vừa uống thuốc”, “uống Paracetamol”, “quên uống” | Xác định thuốc → log (taken/missed/skipped) → có thể hiển thị info/cảnh báo |
| Lịch / hôm nay uống gì | “Hôm nay uống gì?”, “còn thuốc nào?” | Lấy schedule → đối chiếu log → trạng thái còn thiếu |
| Quên / uống muộn | “Quên sáng nay”, “uống bù được không?” | Guideline + khoảng cách liều → gợi ý an toàn (không thay bác sĩ) |
| Tác dụng phụ / triệu chứng | “Buồn nôn sau khi uống”, “thuốc này có tác dụng phụ gì?” | Tra cứu adverse effects + phân tầng mức độ → khuyến cáo cấp cứu / tái khám |
| Tương tác thuốc | “Hai thuốc này uống chung được không?”, “có kỵ rượu không?” | Interaction check + mức độ nghiêm trọng |
| Kiến thức thuốc | “Thuốc này để làm gì?”, “trước hay sau ăn?” | RAG / drug knowledge retrieval |

## Tool layer (hợp đồng logic)

Đặt tên và tham số thống nhất với backend/DB khi có; prototype có thể map sang client.

- `get_patient_medications` — danh mục thuốc đang dùng  
- `log_medication` / `log_dose` — ghi nhận liều (status + thời điểm)  
- `get_today_schedule` / `check_taken_status` — lịch vs log  
- `get_drug_info` — mô tả, cách dùng (từ DB + embedding)  
- `check_side_effects` — triệu chứng ↔ thuốc  
- `check_drug_interaction` — cặp thuốc / thuốc–thức ăn  
- `search_drug_knowledge` — RAG tổng quát  

**Luồng mẫu “tôi uống thuốc”:** intent log → lấy danh sách → **hỏi disambiguation** (A/B/C hoặc tên) → sau khi chọn → log → (tuỳ chọn) `get_drug_info` để giải thích ngắn.

## Kiến trúc dữ liệu (mục tiêu production)

Postgres: bệnh nhân, thuốc (có thể có **embedding** + pgvector), đơn/lịch, **medication_logs**, bảng **interactions**. Chat gateway → **orchestrator** → LLM + tool layer → DB/RAG.

**MedIntel hiện tại (cần khớp khi thiết kế):** một phần thực thi **tool trên client** (lưu local: thuốc, log, ghi chú, reminder draft); server có thể bổ sung RAG/OCR sau. Khi viết prompt, phân biệt rõ tool **server** vs **client** để tránh giả định sai nguồn dữ liệu.

## Các pattern orchestration (chọn theo độ phức tạp)

| Pattern | Ý chính | Khi dùng |
|---------|---------|----------|
| **ReAct** | Think → Act (tool) → Observe → lặp | Chat linh hoạt, nhiều vòng |
| **Plan → Execute** | Planner ra steps cố định rồi executor chạy | Workflow dài, cần ổn định |
| **Graph / state machine** | Node = bước, cạnh = điều kiện | Production, intent rẽ nhánh rõ |
| **Multi-agent** | Coordinator + agent chuyên môn | Tách safety / medication / triage |
| **Tool-calling đơn** | Một vòng LLM → tool → trả lời | RAG đơn giản |

Thực tế hay **kết hợp:** graph hoặc state machine + vòng ReAct ngắn + tool calling; RAG trên Postgres/pgvector.

## Quy tắc prompt & an toàn (bắt buộc nhắc trong system prompt)

- **Luôn:** xác nhận thuốc trước khi log; làm rõ khi mơ hồ; cảnh báo khi triệu chứng nặng / khẩn cấp.  
- **Không:** chẩn đoán bệnh; thay lời bác sĩ; kê đơn / đổi liều.  
- Trả lời ngắn gọn khi phù hợp UI mobile; **structured output** (JSON: `reply`, `tool_calls`, v.v.) khi client cần thực thi cục bộ.

## Khi user yêu cầu “thiết kế agent”

1. Xác định intent(s) từ câu hỏi.  
2. Liệt kê tool cần gọi và thứ tự (có bước hỏi lại không).  
3. Chỉ rõ nguồn dữ liệu: local vs API vs RAG.  
4. Thêm lớp an toàn: từ khóa đỏ (đau ngực, khó thở, dị ứng nặng…) → hướng dẫn cấp cứu / BS.  
5. Nếu production: cân nhắc FHIR, RxNorm, MedDRA — ghi `(cần bổ sung)` nếu chưa có trong dự án.

## Tính năng bổ sung đáng thiết kế

- Phát hiện liều trễ (cron/push) + gợi ý ghi nhận bù.  
- Hỏi chủ động adherence / symptom nhẹ.  
- Điểm tuần (từ log) — khớp dashboard app.
