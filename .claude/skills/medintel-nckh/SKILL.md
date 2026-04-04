---
name: medintel-nckh
description: >-
  Hỗ trợ đề tài NCKH MedIntel (tuân thủ điều trị, AI, mHealth): khớp nội dung với
  báo cáo PDF, cấu trúc chương Phenikaa, khung COM-B/HBM/TPB, và stack trong doc.md.
  Dùng khi viết/sửa báo cáo, slide, đặc tả, kiến trúc MedIntel, OCR+LLM+RAG, Thông tư
  26/2025/TT-BYT, hoặc khi user nhắc bao-cao-nckh-med-2.pdf.
---

# MedIntel — NCKH Phenikaa

## Nguồn chuẩn trong repo

| Nguồn | Nội dung |
|-------|----------|
| `bao-cao-nckh-med-2.pdf` | Báo cáo tổng kết đầy đủ (cấu trúc chương, lập luận, số liệu thứ cấp, bảng biểu) |
| `doc.md` | Tài liệu kỹ thuật ngắn (kiến trúc, module, stack đề xuất cho triển khai) |

Khi có mâu thuẫn giữa hai nguồn: **hỏi user** hoặc ghi rõ hai phương án. Đặc biệt báo cáo PDF có đoạn mô tả stack thiết kế (ví dụ đề cập Python/Flask ở Chương 2) trong khi `doc.md` chọn **FastAPI** — không tự hợp nhất; cần chỉnh sửa có chủ đích theo phiên bản user muốn nộp.

## Định danh đề tài (theo PDF)

- **Trường:** Đại học Phenikaa — Báo cáo tổng kết — Lĩnh vực AI & Y tế, CNTT  
- **Tên đề tài:** *Nghiên cứu giải pháp công nghệ tích hợp trí tuệ nhân tạo nâng cao tuân thủ điều trị*  
- **Giải pháp phần mềm:** **MedIntel** (Medical Intelligence)  
- **Người hướng dẫn (theo bìa PDF):** TS. Mai Thuý Nga  
- **Thông tin sinh viên:** lấy chính xác từ PDF / user; không bịa

## Cấu trúc báo cáo (mục lục PDF)

1. **Phần mở đầu** — Lý do đề tài; tổng quan NC; mục tiêu / nội dung / phương pháp; đối tượng & phạm vi  
2. **Chương 1** — Cơ sở lý thuyết: tuân thủ điều trị & hệ lụy; BMT; đo lường & hành vi (**HBM**, **TPB**, **COM-B**); CNTT y tế & AI  
3. **Chương 2** — Phương pháp: liên ngành; tài liệu thứ cấp; so sánh giải pháp; thiết kế/mô hình hóa (UML, HLD/LLD, WBS); prototyping & kiểm thử (unit, integration, **UAT**)  
4. **Chương 3** — Thực trạng & đặc tả: VN; chính sách & “khoảng trống giám sát” ngoại trú; so sánh sản phẩm; **đặc tả yêu cầu MedIntel**  
5. **Chương 4** — Thiết kế & xây dựng MedIntel: HLD; LLD các phân hệ; CSDL & bảo mật y tế; UI/UX  
6. **Chương 5** — Thực nghiệm: prototype; test cases (PDF có bảng cho OCR & chatbot); thách thức kỹ thuật & pháp lý AI  
7. **Kết luận & kiến nghị**  
8. **Tài liệu tham khảo & phụ lục** — gồm danh mục bảng (tuân thủ, COM-B ↔ tính năng, yêu cầu chức năng/phi chức năng, test case…)

Khi user yêu cầu “viết mục X”: map **đúng số chương/mục** theo PDF để tránh lệch cấu trúc giảng viên.

## Luận điểm cốt lõi cần giữ nhất quán

- **Bối cảnh:** bệnh không lây nhiễm / ngoại trú; gánh nặng tuân thủ; đơn dài ngày (liên quan **Thông tư 26/2025/TT-BYT**, đơn tối đa ~90 ngày) → kéo giãn tái khám → **khoảng trống giám sát** → cần công cụ CNTT.  
- **COM-B:** can thiệp công nghệ bù **Capability** & **Opportunity** (nhắc nhở, OCR giảm nhập tay, kết nối người chăm sóc); tránh chỉ “dọa” **Motivation**.  
- **Rủi ro AI:** hallucination, bảo mật dữ liệu y tế → nhắc **RAG**, kiểm thử, giới hạn vai trò hỗ trợ (không thay thế bác sĩ).  
- **Phương pháp:** chủ yếu **nghiên cứu thứ cấp**, không can thiệp lâm sàng trực tiếp (đúng như PDF).

## Stack & module (theo `doc.md` — triển khai)

- **Mobile:** Flutter, Riverpod, Dio, local notifications; module: auth, prescription scan, reminder, adherence, AI chat, v.v.  
- **Backend:** FastAPI, PostgreSQL, SQLAlchemy, JWT  
- **AI:** OCR đơn thuốc; LLM chatbot; RAG + vector (doc.md đề cập **pgvector**)  
- **Thông báo:** FCM (doc.md)  
- **Lưu file / ảnh:** R2 hoặc S3 (doc.md)

Dùng bảng này khi viết Chương 4 / API / kiến trúc; khi trích từ PDF giữ nguyên thuật ngữ tiếng Việt trong báo cáo.

## Viết cho agent

1. Trích số liệu / trích dẫn từ PDF: chỉ dùng nếu đã có trong PDF hoặc user cung cấp nguồn; không chế thêm nguồn “Patel 2025”, “BV Quân y 105”… nếu không kiểm tra được trong file.  
2. Song ngữ: thuật ngữ chuẩn (OCR, LLM, RAG, UAT, COM-B…) có thể ghi tên đầy đủ lần đầu như báo cáo.  
3. Cập nhật `doc.md` chỉ khi user muốn đồng bộ kỹ thuật; báo cáo formal có thể khác phần “notebook” đầu file.

## Lệnh liên quan

- `/nckh-bao-cao` — khung đoạn văn chương  
- `/tai-lieu-tham-khao` — format tham khảo  
