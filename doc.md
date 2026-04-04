Dựa trên hệ thống MedIntel (AI hỗ trợ tuân thủ điều trị) của bạn, một stack frontend + backend hợp lý cho đồ án nhưng vẫn gần production sẽ như sau 👇

1️⃣ Frontend (Mobile App)
📱 Framework chính

Flutter

Lý do:

Cross-platform (Android + iOS)
UI đẹp, mượt
Dev nhanh cho prototype
Phù hợp đồ án
Cấu trúc Flutter đề xuất
lib/
 ├── core/
 │     ├── theme
 │     ├── constants
 │
 ├── features/
 │     ├── auth
 │     ├── medication
 │     ├── prescription_scan
 │     ├── reminder
 │     ├── adherence
 │     ├── ai_chat
 │
 ├── services/
 │     ├── api_service
 │     ├── notification_service
 │     ├── ocr_service
 │
 ├── models/
 │
 ├── providers/
 │
 └── main.dart
State Management

Khuyên dùng:

Riverpod

hoặc

Bloc

So sánh nhanh:

Tool	Độ khó	Performance
Riverpod	dễ	tốt
Bloc	trung bình	rất tốt

👉 Đồ án: Riverpod

Thư viện Flutter cần thiết
UI
flutter_hooks
flutter_svg
google_fonts
Network
dio
Notification
flutter_local_notifications
Camera / OCR
camera
image_picker
2️⃣ Backend
Framework backend

Khuyên dùng:

FastAPI

Lý do:

API rất nhanh
Python dễ tích hợp AI
Code gọn
phù hợp OCR + LLM
Backend Architecture
backend/
 ├── app/
 │     ├── api
 │     ├── services
 │     ├── models
 │     ├── schemas
 │     ├── repositories
 │
 ├── ai/
 │     ├── ocr
 │     ├── chatbot
 │     ├── rag
 │
 ├── database
 │
 └── main.py
3️⃣ Database
Database chính

PostgreSQL

Lý do:

mạnh
relational tốt cho medical data
support JSON
ORM

SQLAlchemy

4️⃣ AI Layer

MedIntel có 3 AI chính:

OCR đơn thuốc

Có thể dùng:

Tesseract OCR

hoặc

EasyOCR

AI Chatbot

Có thể dùng:

OpenAI API

hoặc

Ollama (local model)

RAG (giải thích thuốc)
Drug database
↓
Vector embedding
↓
AI trả lời

Vector DB:

pgvector

5️⃣ Notification System

Cho nhắc uống thuốc

Local reminder
Flutter Local Notifications
Push notification

Có thể dùng

Firebase Cloud Messaging

6️⃣ Authentication

JWT based

Flow:

Flutter
   ↓
Login API
   ↓
FastAPI
   ↓
JWT token
   ↓
Flutter lưu token

Thư viện:

python-jose
passlib
7️⃣ File Storage

Ảnh đơn thuốc

Có thể dùng:

Amazon S3
Cloudflare R2
8️⃣ API Architecture
Flutter App
      ↓
API Gateway
      ↓
FastAPI Backend
      ↓
Database
      ↓
AI Services
9️⃣ Tech Stack tổng thể (khuyên dùng)
Frontend
Flutter + Riverpod

Backend
FastAPI

Database
PostgreSQL

AI
OCR + LLM + RAG

Storage
Cloudflare R2 / S3

Notification
Firebase
🔟 Kiến trúc chuẩn cho đồ án
Flutter Mobile App
       │
       ▼
   REST API
       │
       ▼
    FastAPI
       │
 ┌─────────────┬──────────────┐
 ▼             ▼              ▼
PostgreSQL   AI Service    Storage
              (OCR+LLM)

✅ Stack này rất hợp với đề tài của bạn vì:

Flutter → mobile healthcare
FastAPI → AI integration
PostgreSQL → medical data
OCR + LLM → AI healthcare assistant

💡 Nếu bạn muốn, mình có thể viết luôn:

System Architecture Diagram (rất đẹp cho CHƯƠNG 4)
MedIntel microservice architecture
API design (REST endpoints)
AI pipeline (OCR → LLM → RAG)

→ để đồ án của bạn trông như một startup AI y tế thật.

mô tả ngắn gọn lại

Dưới đây là mô tả ngắn gọn frontend và backend cho hệ thống MedIntel:

Frontend (Mobile App)

Ứng dụng di động được phát triển bằng Flutter, cho phép xây dựng một mã nguồn chạy trên cả Android và iOS. Flutter được sử dụng để thiết kế giao diện thân thiện với người dùng, hỗ trợ các chức năng như quét đơn thuốc, quản lý lịch uống thuốc, nhắc nhở uống thuốc và tương tác với chatbot AI. Quản lý trạng thái ứng dụng có thể sử dụng Riverpod để đảm bảo hiệu năng và cấu trúc code rõ ràng.

Backend (Server)

Hệ thống backend được xây dựng bằng FastAPI, cung cấp các API để quản lý người dùng, đơn thuốc, lịch uống thuốc và dữ liệu tuân thủ điều trị. Dữ liệu được lưu trữ trong PostgreSQL, đảm bảo khả năng quản lý dữ liệu y tế một cách ổn định và an toàn.

Backend cũng tích hợp các dịch vụ AI, bao gồm nhận dạng văn bản từ đơn thuốc bằng Tesseract OCR và chatbot hỗ trợ tư vấn thuốc dựa trên mô hình ngôn ngữ lớn như OpenAI API.

✅ Tóm lại:

Frontend: Flutter (mobile app cho bệnh nhân)
Backend: FastAPI (REST API server)
Database: PostgreSQL
AI: OCR + AI chatbot hỗ trợ tư vấn và giải thích thuốc

Nếu cần, mình cũng có thể viết phiên bản 4–5 dòng chuẩn học thuật để đưa thẳng vào báo cáo Chương 4 (giảng viên thường thích kiểu đó hơn).

viết doc.md 

Dưới đây là file doc.md ngắn gọn và chuẩn để đưa vào repo hoặc phụ lục đồ án. Mình viết theo format GitHub README / technical doc để nhìn chuyên nghiệp hơn.

# MedIntel System Documentation

## 1. Overview

MedIntel is an AI-powered healthcare application designed to improve medication adherence for patients with chronic diseases.  
The system assists patients in managing prescriptions, understanding medication instructions, and maintaining a consistent treatment schedule.

Core technologies include:

- OCR for prescription recognition
- AI chatbot for medication explanation
- Smart reminders for medication schedules
- Adherence tracking and monitoring

The system is designed with a mobile-first approach to ensure accessibility for elderly patients and caregivers.

---

# 2. System Architecture

The MedIntel system consists of three main layers:

1. Mobile Application (Frontend)
2. Backend API Server
3. AI Services and Database

Architecture overview:


Mobile App (Flutter)
↓
REST API
↓
Backend Server (FastAPI)
↓
Database + AI Services


---

# 3. Frontend

The mobile application is developed using **Flutter**, enabling cross-platform deployment for both Android and iOS.

### Main Responsibilities

- Prescription scanning
- Medication schedule visualization
- Reminder notifications
- AI chatbot interaction
- Adherence tracking dashboard

### Key Technologies

- Flutter
- Riverpod (state management)
- Dio (API communication)
- Flutter Local Notifications

### Main UI Modules

- Onboarding
- Home Dashboard
- Prescription Scanner
- Medication Details
- AI Chat Assistant
- Reminder System
- Adherence Analytics

---

# 4. Backend

The backend is implemented using **FastAPI**, providing high-performance RESTful APIs to manage application logic and data processing.

### Core Responsibilities

- User authentication and management
- Prescription data processing
- Medication scheduling
- Reminder management
- AI integration

### Key Technologies

- FastAPI
- PostgreSQL
- SQLAlchemy ORM
- JWT Authentication

---

# 5. Database

The system uses **PostgreSQL** as the primary relational database.

### Main Tables

- Users
- Prescriptions
- Medications
- MedicationSchedules
- AdherenceLogs
- ChatHistory

The database stores patient medication records, schedules, adherence data, and AI interaction history.

---

## Claude Code & agent (dự án)

| Thành phần | Mô tả |
|------------|--------|
| `CLAUDE.md` | Bộ nhớ dự án; nạp mỗi phiên Claude Code |
| `AGENTS.md` | Tóm tắt cho agent khác; được `@import` trong `CLAUDE.md` |
| `.claude/skills/` | Skill: `/medintel-nckh`, `/nckh-bao-cao`, `/tai-lieu-tham-khao` |
| `.claude/agents/` | Subagent `nckh-reviewer` (rà soát tài liệu, công cụ chỉ đọc/tìm) |
| `.claude/rules/` | Quy tắc theo đường dẫn file (markdown) |
| `.claude/settings.json` | Permission mặc định và cấu hình phiên |

Tài liệu: [Claude Code — thư mục .claude](https://code.claude.com/docs/en/claude-directory).
