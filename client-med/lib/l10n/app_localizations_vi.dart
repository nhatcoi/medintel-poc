// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'MedIntel';

  @override
  String get navHome => 'LỊCH THUỐC';

  @override
  String get navScan => 'QUÉT';

  @override
  String get navChat => 'CHAT';

  @override
  String get navHistory => 'LỊCH SỬ';

  @override
  String get navCare => 'CHĂM SÓC';

  @override
  String get genericYou => 'Bạn';

  @override
  String get genericCancel => 'Hủy';

  @override
  String get gettingStartedHeadline =>
      'Cùng hàng triệu người\nđang chủ động quản lý\nthuốc của mình';

  @override
  String get gettingStartedCta => 'BẮT ĐẦU';

  @override
  String get gettingStartedAccountPrompt => 'Đã có tài khoản? ';

  @override
  String get gettingStartedLogIn => 'Đăng nhập';

  @override
  String get gettingStartedLegal =>
      'Tiếp tục nghĩa là bạn đồng ý Điều khoản và\nđã đọc Chính sách quyền riêng tư';

  @override
  String get patientSetupWelcome => 'Hãy làm quen nhé!\nBạn tên gì?';

  @override
  String get patientSetupFirstName => 'Tên*';

  @override
  String get patientSetupLastName => 'Họ*';

  @override
  String get patientSetupNext => 'Tiếp theo';

  @override
  String get errorConnectionRefused =>
      'Không thể kết nối server. Vui lòng kiểm tra kết nối.';

  @override
  String get errorSaveFailed => 'Không thể lưu thông tin. Vui lòng thử lại.';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsDeleteAllTitle => 'Xóa toàn bộ dữ liệu?';

  @override
  String get settingsDeleteAllBody =>
      'Thao tác này sẽ xóa dữ liệu đồng bộ database trên thiết bị (thuốc, log, cấu hình hiển thị, thông tin onboarding).';

  @override
  String get settingsDeleteData => 'Xóa dữ liệu';

  @override
  String get settingsDisplaySection => 'Hiển thị';

  @override
  String get settingsDisplaySubtitle =>
      'Font và cỡ chữ áp dụng cho toàn bộ ứng dụng.';

  @override
  String get settingsFont => 'Font chữ';

  @override
  String get settingsTextScale => 'Cỡ chữ';

  @override
  String get settingsPreview => 'Xem trước';

  @override
  String get settingsPreviewSample =>
      'Đây là đoạn văn mẫu để bạn chỉnh font và cỡ chữ cho dễ đọc hơn.';

  @override
  String get settingsDebugSection => 'Gỡ lỗi';

  @override
  String get settingsDebugSubtitle =>
      'Toàn bộ state đồng bộ database (thuốc, log liều, ghi chú, auth, prefs) — dùng để trace.';

  @override
  String get settingsClearLocalData =>
      'Xóa dữ liệu database và quay về Welcome';

  @override
  String get settingsLanguageSection => 'Ngôn ngữ';

  @override
  String get settingsLanguageSubtitle =>
      'Chọn Tiếng Việt hoặc English cho toàn bộ ứng dụng.';

  @override
  String get settingsLanguageVi => 'Tiếng Việt';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get medicationAddTitle => 'Thêm thuốc mới';

  @override
  String get medicationDrugName => 'Tên thuốc';

  @override
  String get medicationDrugNameHint => 'Ví dụ: Metformin';

  @override
  String get medicationDosage => 'Liều dùng';

  @override
  String get medicationDosageHint => 'Ví dụ: 500mg x 1 viên';

  @override
  String get medicationSchedule => 'Giờ uống (HH:MM)';

  @override
  String get medicationScheduleHelper => 'Định dạng 24h, ví dụ 08:00';

  @override
  String get medicationSave => 'Lưu thuốc';

  @override
  String get medicationListTitle => 'Quản lý thuốc';

  @override
  String get medicationAddTooltip => 'Thêm thuốc';

  @override
  String get medicationHeaderTitle => 'Danh sách thuốc điều trị';

  @override
  String get medicationHeaderSubtitle => 'Theo dõi thuốc đang dùng mỗi ngày';

  @override
  String get medicationEmptyTitle => 'Chưa có thuốc trong hồ sơ';

  @override
  String get medicationEmptyDescription =>
      'Nhấn nút thêm để tạo lịch uống và theo dõi tuân thủ.';

  @override
  String get medicationEmptyCta => 'Thêm thuốc';

  @override
  String get medicationStatusActive => 'Đang dùng';

  @override
  String get medicationStatusPaused => 'Tạm dừng';

  @override
  String get medicationStatusStopped => 'Ngưng';

  @override
  String get medicationNoDoseTime => 'Chưa có giờ uống';

  @override
  String get reminderTitle => 'Nhắc thuốc hôm nay';

  @override
  String get reminderHeaderTitle => 'Lịch thuốc hôm nay';

  @override
  String get reminderHeaderSubtitle => 'Ưu tiên các liều cần uống trong ngày';

  @override
  String get reminderEmptyTitle => 'Chưa có lịch thuốc để nhắc';

  @override
  String get reminderEmptyDescription =>
      'Hãy thêm thuốc và giờ uống ở màn Quản lý thuốc.';

  @override
  String get reminderScheduleFlexible => 'Không giờ cố định';

  @override
  String get reminderScheduleFixed => 'Có lịch';

  @override
  String get reminderNoDoseTime => 'Chưa có giờ uống';

  @override
  String get reminderNotifyTitle => 'Nhắc uống thuốc';

  @override
  String get reminderNotifyNow => 'Nhắc ngay';

  @override
  String get reminderNow => 'bây giờ';

  @override
  String get reminderTaken => 'Đã uống';

  @override
  String get reminderLate => 'Uống trễ';

  @override
  String get reminderMissed => 'Bỏ lỡ';

  @override
  String reminderLoggedTaken(String name) {
    return 'Đã ghi nhận: $name đã uống đúng liều';
  }

  @override
  String reminderLoggedLate(String name) {
    return 'Đã ghi nhận: $name uống trễ';
  }

  @override
  String reminderLoggedMissed(String name) {
    return 'Đã ghi nhận: bỏ lỡ $name';
  }

  @override
  String reminderLoggedGeneric(String name, String status) {
    return 'Đã ghi nhận $name: $status';
  }

  @override
  String get homeTimeForMedicine => 'ĐẾN GIỜ UỐNG THUỐC';

  @override
  String homeScheduledFor(String time) {
    return 'Hẹn lúc $time';
  }

  @override
  String get homeMarkAsTaken => 'Đánh dấu đã uống';

  @override
  String get homeSnooze => 'Hoãn';

  @override
  String get homeSkip => 'Bỏ qua';

  @override
  String get homeUpcomingToday => 'SẮP TỚI HÔM NAY';

  @override
  String get homeProTipTitle => 'Mẹo nhỏ';

  @override
  String get homeProTipBody =>
      'Uống thuốc cùng bữa ăn giúp giảm kích ứng dạ dày và dễ duy trì thói quen hơn.';

  @override
  String homeAfterDoseTaken(String name) {
    return 'Đã ghi nhận đã uống: $name';
  }

  @override
  String homeAfterDoseSkipped(String name) {
    return 'Đã ghi nhận bỏ qua liều: $name';
  }

  @override
  String get homeServerLogFailed =>
      'Đã lưu trên máy; chưa đồng bộ được server.';

  @override
  String get homeSyncFailed => 'Không tải được danh sách thuốc từ server.';

  @override
  String get homeQuickActionsTitle => 'Thao tác nhanh';

  @override
  String homeSubtitleDosageTime(String dosage, String time) {
    return '$dosage • $time';
  }

  @override
  String get homeEmptyTitle => 'Chưa có lịch thuốc';

  @override
  String get homeEmptyBody =>
      'Thêm thuốc bằng Quét đơn hoặc nhờ trợ lý AI ghi nhận (lưu trên máy bạn). Đồng bộ tài khoản sẽ bổ sung sau.';

  @override
  String get doseStatusTaken => 'ĐÃ UỐNG';

  @override
  String get doseStatusMissed => 'BỎ LỠ';

  @override
  String get doseStatusUpcoming => 'SẮP TỚI';

  @override
  String get doseStatusYesterday => 'Hôm qua';

  @override
  String get scheduleSectionTitle => 'LỊCH THUỐC HÔM NAY';

  @override
  String get scheduleViewCalendar => 'Xem lịch';

  @override
  String get scheduleAlreadyRecorded => 'Đã ghi nhận';

  @override
  String get scheduleMarkAsTaken => 'Đánh dấu đã uống';

  @override
  String get scheduleReschedule => 'Đổi lịch';

  @override
  String get scheduleMarkTaken => 'Đã uống';

  @override
  String get adherenceTitle => 'Tuân thủ điều trị';

  @override
  String get adherenceNoData => 'Chưa có dữ liệu tuân thủ.';

  @override
  String adherenceTotalDoses(int days) {
    return 'Tổng liều ($days ngày)';
  }

  @override
  String get adherenceTakenLabel => 'Đã uống';

  @override
  String get adherenceMissedLabel => 'Bỏ lỡ';

  @override
  String get adherenceSkippedLabel => 'Bỏ qua';

  @override
  String get adherenceLateLabel => 'Uống trễ';

  @override
  String get scanTitle => 'Quét đơn thuốc';

  @override
  String get scanTooltipDismiss => 'Huỷ';

  @override
  String get scanAnalyzing => 'AI đang phân tích đơn thuốc...';

  @override
  String get scanRetry => 'Thử lại';

  @override
  String get scanRetake => 'Chụp lại';

  @override
  String get scanPickImage => 'Chọn ảnh';

  @override
  String scanPickImageError(String error) {
    return 'Không thể chọn ảnh: $error';
  }

  @override
  String get scanEmptyTitle => 'Quét đơn thuốc bằng AI';

  @override
  String get scanEmptyBody =>
      'Chụp ảnh hoặc chọn từ thư viện. AI sẽ tự động nhận diện thuốc, liều dùng và tạo lịch uống.';

  @override
  String get scanCapturePrescription => 'Chụp ảnh đơn thuốc';

  @override
  String get scanFromGallery => 'Chọn từ thư viện';

  @override
  String get scanResultTitle => 'Kết quả phân tích';

  @override
  String scanResultSaved(int count) {
    return 'Đã lưu đơn thuốc ($count thuốc)';
  }

  @override
  String get scanLabelDoctor => 'Bác sĩ';

  @override
  String get scanLabelPatient => 'Bệnh nhân';

  @override
  String get scanLabelDate => 'Ngày';

  @override
  String scanMedsDetected(int count) {
    return 'Thuốc (đã nhận diện $count)';
  }

  @override
  String get scanNoMedsFound =>
      'Không phát hiện thuốc nào. Vui lòng thử chụp lại rõ hơn.';

  @override
  String get scanSchedulePrefix => 'Lịch uống: ';

  @override
  String get treatmentRetry => 'Thử lại';

  @override
  String get notificationChannelName => 'Nhắc uống thuốc';

  @override
  String get notificationChannelDescription =>
      'Thông báo nhắc uống thuốc hằng ngày';

  @override
  String get aiAppBarTitle => 'MedIntel';

  @override
  String aiWelcomeGreeting(String name) {
    return 'Xin chào, $name';
  }

  @override
  String get aiWelcomeBody => 'Trợ lý Meditel';

  @override
  String get aiAssistantBadge => 'TRỢ LÝ MEDINTEL';

  @override
  String get aiComposerHint => 'Hỏi MedIntel bất cứ điều gì…';

  @override
  String get aiConnectionError =>
      'Xin lỗi, không thể kết nối. Vui lòng thử lại.';

  @override
  String get aiSuggestSectionApp => 'Trong ứng dụng';

  @override
  String get aiSuggestSectionKnowledge => 'Kiến thức & tra cứu';

  @override
  String get aiSuggestSectionOther => 'Khác';

  @override
  String get aiChatRotatingCaption => 'Vì sức khỏe của bạn';

  @override
  String get aiChatRotatingFallback0 => 'Hôm nay bạn có khỏe không?';

  @override
  String get aiChatRotatingFallback1 =>
      'Thử nhắn \"Tôi vừa uống thuốc\" để ghi nhận liều, hoặc hỏi tôi về thuốc.';

  @override
  String get aiChatRotatingFallback2 =>
      'Cần thêm toa? Quét đơn ở tab Quét rồi trò chuyện tiếp tại đây.';

  @override
  String get quickScanTitle => 'Quét đơn mới';

  @override
  String get quickScanSubtitle => 'Thêm thuốc bằng AI quét đơn';

  @override
  String get quickChipChat => 'Chat AI';

  @override
  String get quickChipMedication => 'Thuốc';

  @override
  String get quickChipReminder => 'Nhắc nhở';

  @override
  String get adherenceHeroTodayProgress => 'TIẾN ĐỘ HÔM NAY';

  @override
  String get adherenceHeroTakenToday => '  ĐÃ UỐNG HÔM NAY';

  @override
  String get adherenceHeroEmptyHint => 'Hãy thêm thuốc để bắt đầu theo dõi.';

  @override
  String get adherenceHeroProgressHint =>
      'Khởi đầu tốt — tiếp tục duy trì đều đặn để đạt mục tiêu hôm nay.';

  @override
  String get careMonitoringLabel => 'THEO DÕI';

  @override
  String get careMedicationsTitle => 'Thuốc';

  @override
  String get careMedicationsEmpty =>
      'Chưa có thuốc trong danh sách database. Thêm qua Quét đơn hoặc AI Chat.';

  @override
  String get careTodayAdherence => 'Tuân thủ hôm nay';

  @override
  String careDosesLogged(int taken, int total) {
    return '$taken / $total LIỀU ĐÃ GHI';
  }

  @override
  String get careDosesNoSchedule => 'CHƯA CÓ LỊCH LIỀU';

  @override
  String get careWeeklyScore => 'Điểm tuần';

  @override
  String get careRecentAlerts => 'Cảnh báo gần đây';

  @override
  String get careAlertsEmpty =>
      'Không có cảnh báo gần đây (theo dữ liệu database).';

  @override
  String get careVitalsDisconnected => 'CHƯA KẾT NỐI';

  @override
  String get careVitalsSubtitle => 'Sinh hiệu — tích hợp thiết bị sau';

  @override
  String get careOpenAiChat => 'MỞ CHAT AI';

  @override
  String get weeklyCaptionGood => 'TIẾN ĐỘ TỐT';

  @override
  String get weeklyCaptionOk => 'ĐANG ỔN ĐỊNH';

  @override
  String get weeklyCaptionWatch => 'CẦN THEO DÕI THÊM';

  @override
  String get weeklyCaptionNoData => 'CHƯA CÓ DỮ LIỆU TUẦN';

  @override
  String get dashMedFallback => 'Thuốc';

  @override
  String get dashTimeInDay => 'Trong ngày';

  @override
  String dashTimeAm(String hour, String minute) {
    return '$hour:$minute SA';
  }

  @override
  String dashTimePm(String hour12, String minute) {
    return '$hour12:$minute CH';
  }

  @override
  String get dashUserFallback => 'Người dùng';

  @override
  String dashAlertMissedTitle(String patientName) {
    return '$patientName bỏ lỡ / bỏ qua liều';
  }

  @override
  String dashAlertMissedSubtitle(String medName, String note) {
    return '$medName • hôm nay ($note)';
  }

  @override
  String get dashAlertCareNote => 'Ghi chú chăm sóc';

  @override
  String get dashTodayLocalNote => 'dữ liệu database';

  @override
  String get localDataTitle => 'Dữ liệu database (JSON)';

  @override
  String get localDataRefresh => 'Làm mới';

  @override
  String localDataRefreshNote(int seconds) {
    return 'Tự làm mới mỗi ${seconds}s (đọc lại state đồng bộ database / cache thiết bị).';
  }

  @override
  String get authTitle => 'Đăng nhập';

  @override
  String get authBody => 'auth — JWT login';

  @override
  String get placeholderScanTitle => 'Quét đơn thuốc';

  @override
  String get placeholderScanBody => 'prescription_scan — camera + OCR';
}
