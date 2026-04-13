import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'MedIntel'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In vi, this message translates to:
  /// **'LỊCH THUỐC'**
  String get navHome;

  /// No description provided for @navScan.
  ///
  /// In vi, this message translates to:
  /// **'QUÉT'**
  String get navScan;

  /// No description provided for @navChat.
  ///
  /// In vi, this message translates to:
  /// **'CHAT'**
  String get navChat;

  /// No description provided for @navHistory.
  ///
  /// In vi, this message translates to:
  /// **'LỊCH SỬ'**
  String get navHistory;

  /// No description provided for @navCare.
  ///
  /// In vi, this message translates to:
  /// **'CHĂM SÓC'**
  String get navCare;

  /// No description provided for @genericYou.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get genericYou;

  /// No description provided for @genericCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get genericCancel;

  /// No description provided for @gettingStartedHeadline.
  ///
  /// In vi, this message translates to:
  /// **'Cùng hàng triệu người\nđang chủ động quản lý\nthuốc của mình'**
  String get gettingStartedHeadline;

  /// No description provided for @gettingStartedCta.
  ///
  /// In vi, this message translates to:
  /// **'BẮT ĐẦU'**
  String get gettingStartedCta;

  /// No description provided for @gettingStartedAccountPrompt.
  ///
  /// In vi, this message translates to:
  /// **'Đã có tài khoản? '**
  String get gettingStartedAccountPrompt;

  /// No description provided for @gettingStartedLogIn.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get gettingStartedLogIn;

  /// No description provided for @gettingStartedLegal.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục nghĩa là bạn đồng ý Điều khoản và\nđã đọc Chính sách quyền riêng tư'**
  String get gettingStartedLegal;

  /// No description provided for @patientSetupWelcome.
  ///
  /// In vi, this message translates to:
  /// **'Hãy làm quen nhé!\nBạn tên gì?'**
  String get patientSetupWelcome;

  /// No description provided for @patientSetupFirstName.
  ///
  /// In vi, this message translates to:
  /// **'Tên*'**
  String get patientSetupFirstName;

  /// No description provided for @patientSetupLastName.
  ///
  /// In vi, this message translates to:
  /// **'Họ*'**
  String get patientSetupLastName;

  /// No description provided for @patientSetupNext.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp theo'**
  String get patientSetupNext;

  /// No description provided for @errorConnectionRefused.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết nối server. Vui lòng kiểm tra kết nối.'**
  String get errorConnectionRefused;

  /// No description provided for @errorSaveFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể lưu thông tin. Vui lòng thử lại.'**
  String get errorSaveFailed;

  /// No description provided for @settingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsTitle;

  /// No description provided for @settingsDeleteAllTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa toàn bộ dữ liệu?'**
  String get settingsDeleteAllTitle;

  /// No description provided for @settingsDeleteAllBody.
  ///
  /// In vi, this message translates to:
  /// **'Thao tác này sẽ xóa dữ liệu đồng bộ database trên thiết bị (thuốc, log, cấu hình hiển thị, thông tin onboarding).'**
  String get settingsDeleteAllBody;

  /// No description provided for @settingsDeleteData.
  ///
  /// In vi, this message translates to:
  /// **'Xóa dữ liệu'**
  String get settingsDeleteData;

  /// No description provided for @settingsDisplaySection.
  ///
  /// In vi, this message translates to:
  /// **'Hiển thị'**
  String get settingsDisplaySection;

  /// No description provided for @settingsDisplaySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Font và cỡ chữ áp dụng cho toàn bộ ứng dụng.'**
  String get settingsDisplaySubtitle;

  /// No description provided for @settingsFont.
  ///
  /// In vi, this message translates to:
  /// **'Font chữ'**
  String get settingsFont;

  /// No description provided for @settingsTextScale.
  ///
  /// In vi, this message translates to:
  /// **'Cỡ chữ'**
  String get settingsTextScale;

  /// No description provided for @settingsPreview.
  ///
  /// In vi, this message translates to:
  /// **'Xem trước'**
  String get settingsPreview;

  /// No description provided for @settingsPreviewSample.
  ///
  /// In vi, this message translates to:
  /// **'Đây là đoạn văn mẫu để bạn chỉnh font và cỡ chữ cho dễ đọc hơn.'**
  String get settingsPreviewSample;

  /// No description provided for @settingsDebugSection.
  ///
  /// In vi, this message translates to:
  /// **'Gỡ lỗi'**
  String get settingsDebugSection;

  /// No description provided for @settingsDebugSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Toàn bộ state đồng bộ database (thuốc, log liều, ghi chú, auth, prefs) — dùng để trace.'**
  String get settingsDebugSubtitle;

  /// No description provided for @settingsClearLocalData.
  ///
  /// In vi, this message translates to:
  /// **'Xóa dữ liệu database và quay về Welcome'**
  String get settingsClearLocalData;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn Tiếng Việt hoặc English cho toàn bộ ứng dụng.'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsLanguageVi.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get settingsLanguageVi;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @medicationAddTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thuốc mới'**
  String get medicationAddTitle;

  /// No description provided for @medicationDrugName.
  ///
  /// In vi, this message translates to:
  /// **'Tên thuốc'**
  String get medicationDrugName;

  /// No description provided for @medicationDrugNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Metformin'**
  String get medicationDrugNameHint;

  /// No description provided for @medicationDosage.
  ///
  /// In vi, this message translates to:
  /// **'Liều dùng'**
  String get medicationDosage;

  /// No description provided for @medicationDosageHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: 500mg x 1 viên'**
  String get medicationDosageHint;

  /// No description provided for @medicationSchedule.
  ///
  /// In vi, this message translates to:
  /// **'Giờ uống (HH:MM)'**
  String get medicationSchedule;

  /// No description provided for @medicationScheduleHelper.
  ///
  /// In vi, this message translates to:
  /// **'Định dạng 24h, ví dụ 08:00'**
  String get medicationScheduleHelper;

  /// No description provided for @medicationSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thuốc'**
  String get medicationSave;

  /// No description provided for @medicationListTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý thuốc'**
  String get medicationListTitle;

  /// No description provided for @medicationAddTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thuốc'**
  String get medicationAddTooltip;

  /// No description provided for @medicationHeaderTitle.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách thuốc điều trị'**
  String get medicationHeaderTitle;

  /// No description provided for @medicationHeaderSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi thuốc đang dùng mỗi ngày'**
  String get medicationHeaderSubtitle;

  /// No description provided for @medicationEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thuốc trong hồ sơ'**
  String get medicationEmptyTitle;

  /// No description provided for @medicationEmptyDescription.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn nút thêm để tạo lịch uống và theo dõi tuân thủ.'**
  String get medicationEmptyDescription;

  /// No description provided for @medicationEmptyCta.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thuốc'**
  String get medicationEmptyCta;

  /// No description provided for @medicationStatusActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang dùng'**
  String get medicationStatusActive;

  /// No description provided for @medicationStatusPaused.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng'**
  String get medicationStatusPaused;

  /// No description provided for @medicationStatusStopped.
  ///
  /// In vi, this message translates to:
  /// **'Ngưng'**
  String get medicationStatusStopped;

  /// No description provided for @medicationNoDoseTime.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giờ uống'**
  String get medicationNoDoseTime;

  /// No description provided for @reminderTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc thuốc hôm nay'**
  String get reminderTitle;

  /// No description provided for @reminderHeaderTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch thuốc hôm nay'**
  String get reminderHeaderTitle;

  /// No description provided for @reminderHeaderSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ưu tiên các liều cần uống trong ngày'**
  String get reminderHeaderSubtitle;

  /// No description provided for @reminderEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch thuốc để nhắc'**
  String get reminderEmptyTitle;

  /// No description provided for @reminderEmptyDescription.
  ///
  /// In vi, this message translates to:
  /// **'Hãy thêm thuốc và giờ uống ở màn Quản lý thuốc.'**
  String get reminderEmptyDescription;

  /// No description provided for @reminderScheduleFlexible.
  ///
  /// In vi, this message translates to:
  /// **'Không giờ cố định'**
  String get reminderScheduleFlexible;

  /// No description provided for @reminderScheduleFixed.
  ///
  /// In vi, this message translates to:
  /// **'Có lịch'**
  String get reminderScheduleFixed;

  /// No description provided for @reminderNoDoseTime.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giờ uống'**
  String get reminderNoDoseTime;

  /// No description provided for @reminderNotifyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc uống thuốc'**
  String get reminderNotifyTitle;

  /// No description provided for @reminderNotifyNow.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc ngay'**
  String get reminderNotifyNow;

  /// No description provided for @reminderNow.
  ///
  /// In vi, this message translates to:
  /// **'bây giờ'**
  String get reminderNow;

  /// No description provided for @reminderTaken.
  ///
  /// In vi, this message translates to:
  /// **'Đã uống'**
  String get reminderTaken;

  /// No description provided for @reminderLate.
  ///
  /// In vi, this message translates to:
  /// **'Uống trễ'**
  String get reminderLate;

  /// No description provided for @reminderMissed.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ lỡ'**
  String get reminderMissed;

  /// No description provided for @reminderLoggedTaken.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận: {name} đã uống đúng liều'**
  String reminderLoggedTaken(String name);

  /// No description provided for @reminderLoggedLate.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận: {name} uống trễ'**
  String reminderLoggedLate(String name);

  /// No description provided for @reminderLoggedMissed.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận: bỏ lỡ {name}'**
  String reminderLoggedMissed(String name);

  /// No description provided for @reminderLoggedGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận {name}: {status}'**
  String reminderLoggedGeneric(String name, String status);

  /// No description provided for @homeTimeForMedicine.
  ///
  /// In vi, this message translates to:
  /// **'ĐẾN GIỜ UỐNG THUỐC'**
  String get homeTimeForMedicine;

  /// No description provided for @homeScheduledFor.
  ///
  /// In vi, this message translates to:
  /// **'Hẹn lúc {time}'**
  String homeScheduledFor(String time);

  /// No description provided for @homeMarkAsTaken.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu đã uống'**
  String get homeMarkAsTaken;

  /// No description provided for @homeSnooze.
  ///
  /// In vi, this message translates to:
  /// **'Hoãn'**
  String get homeSnooze;

  /// No description provided for @homeSkip.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get homeSkip;

  /// No description provided for @homeUpcomingToday.
  ///
  /// In vi, this message translates to:
  /// **'SẮP TỚI HÔM NAY'**
  String get homeUpcomingToday;

  /// No description provided for @homeProTipTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mẹo nhỏ'**
  String get homeProTipTitle;

  /// No description provided for @homeProTipBody.
  ///
  /// In vi, this message translates to:
  /// **'Uống thuốc cùng bữa ăn giúp giảm kích ứng dạ dày và dễ duy trì thói quen hơn.'**
  String get homeProTipBody;

  /// No description provided for @homeAfterDoseTaken.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận đã uống: {name}'**
  String homeAfterDoseTaken(String name);

  /// No description provided for @homeAfterDoseSkipped.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận bỏ qua liều: {name}'**
  String homeAfterDoseSkipped(String name);

  /// No description provided for @homeServerLogFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu trên máy; chưa đồng bộ được server.'**
  String get homeServerLogFailed;

  /// No description provided for @homeSyncFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách thuốc từ server.'**
  String get homeSyncFailed;

  /// No description provided for @homeQuickActionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thao tác nhanh'**
  String get homeQuickActionsTitle;

  /// No description provided for @homeSubtitleDosageTime.
  ///
  /// In vi, this message translates to:
  /// **'{dosage} • {time}'**
  String homeSubtitleDosageTime(String dosage, String time);

  /// No description provided for @homeEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch thuốc'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thuốc bằng Quét đơn hoặc nhờ trợ lý AI ghi nhận (lưu trên máy bạn). Đồng bộ tài khoản sẽ bổ sung sau.'**
  String get homeEmptyBody;

  /// No description provided for @doseStatusTaken.
  ///
  /// In vi, this message translates to:
  /// **'ĐÃ UỐNG'**
  String get doseStatusTaken;

  /// No description provided for @doseStatusMissed.
  ///
  /// In vi, this message translates to:
  /// **'BỎ LỠ'**
  String get doseStatusMissed;

  /// No description provided for @doseStatusUpcoming.
  ///
  /// In vi, this message translates to:
  /// **'SẮP TỚI'**
  String get doseStatusUpcoming;

  /// No description provided for @doseStatusYesterday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get doseStatusYesterday;

  /// No description provided for @scheduleSectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'LỊCH THUỐC HÔM NAY'**
  String get scheduleSectionTitle;

  /// No description provided for @scheduleViewCalendar.
  ///
  /// In vi, this message translates to:
  /// **'Xem lịch'**
  String get scheduleViewCalendar;

  /// No description provided for @scheduleAlreadyRecorded.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận'**
  String get scheduleAlreadyRecorded;

  /// No description provided for @scheduleMarkAsTaken.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu đã uống'**
  String get scheduleMarkAsTaken;

  /// No description provided for @scheduleReschedule.
  ///
  /// In vi, this message translates to:
  /// **'Đổi lịch'**
  String get scheduleReschedule;

  /// No description provided for @scheduleMarkTaken.
  ///
  /// In vi, this message translates to:
  /// **'Đã uống'**
  String get scheduleMarkTaken;

  /// No description provided for @adherenceTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tuân thủ điều trị'**
  String get adherenceTitle;

  /// No description provided for @adherenceNoData.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu tuân thủ.'**
  String get adherenceNoData;

  /// No description provided for @adherenceTotalDoses.
  ///
  /// In vi, this message translates to:
  /// **'Tổng liều ({days} ngày)'**
  String adherenceTotalDoses(int days);

  /// No description provided for @adherenceTakenLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đã uống'**
  String get adherenceTakenLabel;

  /// No description provided for @adherenceMissedLabel.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ lỡ'**
  String get adherenceMissedLabel;

  /// No description provided for @adherenceSkippedLabel.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get adherenceSkippedLabel;

  /// No description provided for @adherenceLateLabel.
  ///
  /// In vi, this message translates to:
  /// **'Uống trễ'**
  String get adherenceLateLabel;

  /// No description provided for @scanTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quét đơn thuốc'**
  String get scanTitle;

  /// No description provided for @scanTooltipDismiss.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get scanTooltipDismiss;

  /// No description provided for @scanAnalyzing.
  ///
  /// In vi, this message translates to:
  /// **'AI đang phân tích đơn thuốc...'**
  String get scanAnalyzing;

  /// No description provided for @scanRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get scanRetry;

  /// No description provided for @scanRetake.
  ///
  /// In vi, this message translates to:
  /// **'Chụp lại'**
  String get scanRetake;

  /// No description provided for @scanPickImage.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh'**
  String get scanPickImage;

  /// No description provided for @scanPickImageError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể chọn ảnh: {error}'**
  String scanPickImageError(String error);

  /// No description provided for @scanEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quét đơn thuốc bằng AI'**
  String get scanEmptyTitle;

  /// No description provided for @scanEmptyBody.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh hoặc chọn từ thư viện. AI sẽ tự động nhận diện thuốc, liều dùng và tạo lịch uống.'**
  String get scanEmptyBody;

  /// No description provided for @scanCapturePrescription.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh đơn thuốc'**
  String get scanCapturePrescription;

  /// No description provided for @scanFromGallery.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ thư viện'**
  String get scanFromGallery;

  /// No description provided for @scanResultTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả phân tích'**
  String get scanResultTitle;

  /// No description provided for @scanResultSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu đơn thuốc ({count} thuốc)'**
  String scanResultSaved(int count);

  /// No description provided for @scanLabelDoctor.
  ///
  /// In vi, this message translates to:
  /// **'Bác sĩ'**
  String get scanLabelDoctor;

  /// No description provided for @scanLabelPatient.
  ///
  /// In vi, this message translates to:
  /// **'Bệnh nhân'**
  String get scanLabelPatient;

  /// No description provided for @scanLabelDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get scanLabelDate;

  /// No description provided for @scanMedsDetected.
  ///
  /// In vi, this message translates to:
  /// **'Thuốc (đã nhận diện {count})'**
  String scanMedsDetected(int count);

  /// No description provided for @scanNoMedsFound.
  ///
  /// In vi, this message translates to:
  /// **'Không phát hiện thuốc nào. Vui lòng thử chụp lại rõ hơn.'**
  String get scanNoMedsFound;

  /// No description provided for @scanSchedulePrefix.
  ///
  /// In vi, this message translates to:
  /// **'Lịch uống: '**
  String get scanSchedulePrefix;

  /// No description provided for @treatmentRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get treatmentRetry;

  /// No description provided for @notificationChannelName.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc uống thuốc'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo nhắc uống thuốc hằng ngày'**
  String get notificationChannelDescription;

  /// No description provided for @aiAppBarTitle.
  ///
  /// In vi, this message translates to:
  /// **'MedIntel'**
  String get aiAppBarTitle;

  /// No description provided for @aiWelcomeGreeting.
  ///
  /// In vi, this message translates to:
  /// **'Xin chào, {name}'**
  String aiWelcomeGreeting(String name);

  /// No description provided for @aiWelcomeBody.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý Meditel'**
  String get aiWelcomeBody;

  /// No description provided for @aiAssistantBadge.
  ///
  /// In vi, this message translates to:
  /// **'TRỢ LÝ MEDINTEL'**
  String get aiAssistantBadge;

  /// No description provided for @aiComposerHint.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi MedIntel bất cứ điều gì…'**
  String get aiComposerHint;

  /// No description provided for @aiConnectionError.
  ///
  /// In vi, this message translates to:
  /// **'Xin lỗi, không thể kết nối. Vui lòng thử lại.'**
  String get aiConnectionError;

  /// No description provided for @aiSuggestSectionApp.
  ///
  /// In vi, this message translates to:
  /// **'Trong ứng dụng'**
  String get aiSuggestSectionApp;

  /// No description provided for @aiSuggestSectionKnowledge.
  ///
  /// In vi, this message translates to:
  /// **'Kiến thức & tra cứu'**
  String get aiSuggestSectionKnowledge;

  /// No description provided for @aiSuggestSectionOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get aiSuggestSectionOther;

  /// No description provided for @aiChatRotatingCaption.
  ///
  /// In vi, this message translates to:
  /// **'Vì sức khỏe của bạn'**
  String get aiChatRotatingCaption;

  /// No description provided for @aiChatRotatingFallback0.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay bạn có khỏe không?'**
  String get aiChatRotatingFallback0;

  /// No description provided for @aiChatRotatingFallback1.
  ///
  /// In vi, this message translates to:
  /// **'Thử nhắn \"Tôi vừa uống thuốc\" để ghi nhận liều, hoặc hỏi tôi về thuốc.'**
  String get aiChatRotatingFallback1;

  /// No description provided for @aiChatRotatingFallback2.
  ///
  /// In vi, this message translates to:
  /// **'Cần thêm toa? Quét đơn ở tab Quét rồi trò chuyện tiếp tại đây.'**
  String get aiChatRotatingFallback2;

  /// No description provided for @quickScanTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quét đơn mới'**
  String get quickScanTitle;

  /// No description provided for @quickScanSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thuốc bằng AI quét đơn'**
  String get quickScanSubtitle;

  /// No description provided for @quickChipChat.
  ///
  /// In vi, this message translates to:
  /// **'Chat AI'**
  String get quickChipChat;

  /// No description provided for @quickChipMedication.
  ///
  /// In vi, this message translates to:
  /// **'Thuốc'**
  String get quickChipMedication;

  /// No description provided for @quickChipReminder.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc nhở'**
  String get quickChipReminder;

  /// No description provided for @adherenceHeroTodayProgress.
  ///
  /// In vi, this message translates to:
  /// **'TIẾN ĐỘ HÔM NAY'**
  String get adherenceHeroTodayProgress;

  /// No description provided for @adherenceHeroTakenToday.
  ///
  /// In vi, this message translates to:
  /// **'  ĐÃ UỐNG HÔM NAY'**
  String get adherenceHeroTakenToday;

  /// No description provided for @adherenceHeroEmptyHint.
  ///
  /// In vi, this message translates to:
  /// **'Hãy thêm thuốc để bắt đầu theo dõi.'**
  String get adherenceHeroEmptyHint;

  /// No description provided for @adherenceHeroProgressHint.
  ///
  /// In vi, this message translates to:
  /// **'Khởi đầu tốt — tiếp tục duy trì đều đặn để đạt mục tiêu hôm nay.'**
  String get adherenceHeroProgressHint;

  /// No description provided for @careMonitoringLabel.
  ///
  /// In vi, this message translates to:
  /// **'THEO DÕI'**
  String get careMonitoringLabel;

  /// No description provided for @careMedicationsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thuốc'**
  String get careMedicationsTitle;

  /// No description provided for @careMedicationsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thuốc trong danh sách database. Thêm qua Quét đơn hoặc AI Chat.'**
  String get careMedicationsEmpty;

  /// No description provided for @careTodayAdherence.
  ///
  /// In vi, this message translates to:
  /// **'Tuân thủ hôm nay'**
  String get careTodayAdherence;

  /// No description provided for @careDosesLogged.
  ///
  /// In vi, this message translates to:
  /// **'{taken} / {total} LIỀU ĐÃ GHI'**
  String careDosesLogged(int taken, int total);

  /// No description provided for @careDosesNoSchedule.
  ///
  /// In vi, this message translates to:
  /// **'CHƯA CÓ LỊCH LIỀU'**
  String get careDosesNoSchedule;

  /// No description provided for @careWeeklyScore.
  ///
  /// In vi, this message translates to:
  /// **'Điểm tuần'**
  String get careWeeklyScore;

  /// No description provided for @careRecentAlerts.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo gần đây'**
  String get careRecentAlerts;

  /// No description provided for @careAlertsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có cảnh báo gần đây (theo dữ liệu database).'**
  String get careAlertsEmpty;

  /// No description provided for @careVitalsDisconnected.
  ///
  /// In vi, this message translates to:
  /// **'CHƯA KẾT NỐI'**
  String get careVitalsDisconnected;

  /// No description provided for @careVitalsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Sinh hiệu — tích hợp thiết bị sau'**
  String get careVitalsSubtitle;

  /// No description provided for @careOpenAiChat.
  ///
  /// In vi, this message translates to:
  /// **'MỞ CHAT AI'**
  String get careOpenAiChat;

  /// No description provided for @weeklyCaptionGood.
  ///
  /// In vi, this message translates to:
  /// **'TIẾN ĐỘ TỐT'**
  String get weeklyCaptionGood;

  /// No description provided for @weeklyCaptionOk.
  ///
  /// In vi, this message translates to:
  /// **'ĐANG ỔN ĐỊNH'**
  String get weeklyCaptionOk;

  /// No description provided for @weeklyCaptionWatch.
  ///
  /// In vi, this message translates to:
  /// **'CẦN THEO DÕI THÊM'**
  String get weeklyCaptionWatch;

  /// No description provided for @weeklyCaptionNoData.
  ///
  /// In vi, this message translates to:
  /// **'CHƯA CÓ DỮ LIỆU TUẦN'**
  String get weeklyCaptionNoData;

  /// No description provided for @dashMedFallback.
  ///
  /// In vi, this message translates to:
  /// **'Thuốc'**
  String get dashMedFallback;

  /// No description provided for @dashTimeInDay.
  ///
  /// In vi, this message translates to:
  /// **'Trong ngày'**
  String get dashTimeInDay;

  /// No description provided for @dashTimeAm.
  ///
  /// In vi, this message translates to:
  /// **'{hour}:{minute} SA'**
  String dashTimeAm(String hour, String minute);

  /// No description provided for @dashTimePm.
  ///
  /// In vi, this message translates to:
  /// **'{hour12}:{minute} CH'**
  String dashTimePm(String hour12, String minute);

  /// No description provided for @dashUserFallback.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get dashUserFallback;

  /// No description provided for @dashAlertMissedTitle.
  ///
  /// In vi, this message translates to:
  /// **'{patientName} bỏ lỡ / bỏ qua liều'**
  String dashAlertMissedTitle(String patientName);

  /// No description provided for @dashAlertMissedSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'{medName} • hôm nay ({note})'**
  String dashAlertMissedSubtitle(String medName, String note);

  /// No description provided for @dashAlertCareNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú chăm sóc'**
  String get dashAlertCareNote;

  /// No description provided for @dashTodayLocalNote.
  ///
  /// In vi, this message translates to:
  /// **'dữ liệu database'**
  String get dashTodayLocalNote;

  /// No description provided for @localDataTitle.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu database (JSON)'**
  String get localDataTitle;

  /// No description provided for @localDataRefresh.
  ///
  /// In vi, this message translates to:
  /// **'Làm mới'**
  String get localDataRefresh;

  /// No description provided for @localDataRefreshNote.
  ///
  /// In vi, this message translates to:
  /// **'Tự làm mới mỗi {seconds}s (đọc lại state đồng bộ database / cache thiết bị).'**
  String localDataRefreshNote(int seconds);

  /// No description provided for @authTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get authTitle;

  /// No description provided for @authBody.
  ///
  /// In vi, this message translates to:
  /// **'auth — JWT login'**
  String get authBody;

  /// No description provided for @placeholderScanTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quét đơn thuốc'**
  String get placeholderScanTitle;

  /// No description provided for @placeholderScanBody.
  ///
  /// In vi, this message translates to:
  /// **'prescription_scan — camera + OCR'**
  String get placeholderScanBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
