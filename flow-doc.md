1. profile
- Thu thập thông tin cá nhân user, thông tin y tế, điều trị khi lần đầu vào app
- Hiển thị flow screen thu thập ở lần đầu khi vào app - hoặc khi thêm care giver (khi thêm care giver - không điền mật khẩu như lúc mới vào app, vì care giver là người được quản lí điều trị)
Ví dụ :
{
  "full_name": "Nhật Nhật",
  "date_of_birth": "1998-07-20",
  "email": "nhat@example.com",
  "phone_number": "0901234567",
  "emergency_contact": "0907654321",
  "chronic_conditions": ["Tăng huyết áp"],
  "allergies": ["Penicillin"],
  "current_medications": ["Amlodipine 5mg"],
  "primary_diagnosis": "Tăng huyết áp",
  "treatment_status": "active",
  "medical_notes": "Đôi khi chóng mặt buổi sáng"
}


2.  Thuốc + Lịch + Log tuân thủ (core) chi tiết
- Thuốc: 
+ Thêm thuốc: hiện ô search thuốc từ kho data thuốc -> full text search cho dễ search, search tên thuốc, triệu chứng - tối ưu search với 70k data đó. nếu không có -> tool call search web search thuốc. hoặc tự thêm thuốc tùy ý -> 
  + Flow thêm thuốc:
    1) User nhập tên thuốc / triệu chứng vào ô search.
    2) App gọi API search thuốc nội bộ (ưu tiên kho 70k).
    3) Nếu có kết quả:
       - hiển thị danh sách gợi ý (tên thuốc, hoạt chất, dạng bào chế, liều thường dùng).
       - user chọn 1 thuốc -> mở form confirm.
    4) Nếu không có kết quả:
       - cho phép "Tìm web" (tool call web search thuốc, lấy thông tin tham khảo).
       - hoặc "Thêm thủ công" (nhập tên, liều, tần suất, ghi chú).
    5) User lưu -> tạo medication + schedule mặc định.
    6) Hệ thống trả về medication_id để dùng cho lịch/log/chat context.

  + Form thêm/sửa thuốc tối thiểu:
    - medication_name (bắt buộc)
    - dosage (liều)
    - frequency (số lần/ngày)
    - instructions (trước/sau ăn, lưu ý)
    - start_date / end_date
    - schedule_times (nhiều mốc giờ)

  + Sửa thuốc:
    - Cho phép sửa tên, liều, tần suất, lịch giờ, trạng thái active/inactive.
    - Nếu đổi lịch giờ -> cập nhật schedule liên quan, không mất log cũ.

  + Xóa thuốc:
    - Xóa mềm (status = inactive) để giữ lịch sử log tuân thủ.
    - Có tùy chọn xóa cứng chỉ dành cho dữ liệu nhập nhầm.

  + Search tối ưu cho 70k dữ liệu:
    - Ưu tiên full-text + trigram (tên thuốc, hoạt chất, triệu chứng/chỉ định).
    - Có ranking theo độ khớp + độ phổ biến.
    - Debounce 300-500ms phía client để giảm load.
    - Cache query gần nhất để UX mượt hơn.

  + API đề xuất cho nhóm Thuốc:
    - GET /api/v1/treatment/medications/search?q=
    - POST /api/v1/treatment/medications
    - PATCH /api/v1/treatment/medications/{medication_id}
    - DELETE /api/v1/treatment/medications/{medication_id}
    - GET /api/v1/treatment/medications?profile_id=

  + Kết quả mong muốn:
    - Thêm thuốc nhanh (search nội bộ hoặc thêm tay).
    - Dữ liệu thuốc chuẩn để feed vào lịch uống, log tuân thủ và AI chat.