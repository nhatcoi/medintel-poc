// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MedIntel';

  @override
  String get navHome => 'MED SCHEDULE';

  @override
  String get navScan => 'SCAN';

  @override
  String get navChat => 'CHAT';

  @override
  String get navHistory => 'HISTORY';

  @override
  String get navCare => 'CARE';

  @override
  String get genericYou => 'You';

  @override
  String get genericCancel => 'Cancel';

  @override
  String get gettingStartedHeadline =>
      'Join millions of people\nalready taking control of\ntheir meds';

  @override
  String get gettingStartedCta => 'GET STARTED';

  @override
  String get gettingStartedAccountPrompt => 'Already have an account? ';

  @override
  String get gettingStartedLogIn => 'Log in';

  @override
  String get gettingStartedLegal =>
      'By proceeding, you agree to our Terms and that\nyou have read our Privacy Policy';

  @override
  String get patientSetupWelcome =>
      'Let\'s get to know you better!\nWhat\'s your name?';

  @override
  String get patientSetupFirstName => 'First name*';

  @override
  String get patientSetupLastName => 'Last name*';

  @override
  String get patientSetupNext => 'Next';

  @override
  String get errorConnectionRefused =>
      'Cannot reach the server. Please check your connection.';

  @override
  String get errorSaveFailed =>
      'Could not save your information. Please try again.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDeleteAllTitle => 'Delete all data?';

  @override
  String get settingsDeleteAllBody =>
      'This removes device-cached data synced with the database (medications, logs, display settings, onboarding).';

  @override
  String get settingsDeleteData => 'Delete data';

  @override
  String get settingsDisplaySection => 'Display';

  @override
  String get settingsDisplaySubtitle =>
      'Font and text size apply across the app.';

  @override
  String get settingsFont => 'Font';

  @override
  String get settingsTextScale => 'Text size';

  @override
  String get settingsPreview => 'Preview';

  @override
  String get settingsPreviewSample =>
      'Sample text so you can tune font and size for readability.';

  @override
  String get settingsDebugSection => 'Debug';

  @override
  String get settingsDebugSubtitle =>
      'Full database-sync state snapshot (meds, dose logs, notes, auth, prefs) for tracing.';

  @override
  String get settingsClearLocalData =>
      'Clear database data and return to Welcome';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsLanguageSubtitle =>
      'Choose Vietnamese or English for the whole app.';

  @override
  String get settingsLanguageVi => 'Vietnamese';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get medicationAddTitle => 'Add medication';

  @override
  String get medicationDrugName => 'Medication name';

  @override
  String get medicationDrugNameHint => 'e.g. Metformin';

  @override
  String get medicationDosage => 'Dosage';

  @override
  String get medicationDosageHint => 'e.g. 500mg × 1 tablet';

  @override
  String get medicationSchedule => 'Time (HH:MM)';

  @override
  String get medicationScheduleHelper => '24h format, e.g. 08:00';

  @override
  String get medicationSave => 'Save medication';

  @override
  String get medicationListTitle => 'Medications';

  @override
  String get medicationAddTooltip => 'Add medication';

  @override
  String get medicationHeaderTitle => 'Treatment list';

  @override
  String get medicationHeaderSubtitle => 'Track what you take every day';

  @override
  String get medicationEmptyTitle => 'No medications yet';

  @override
  String get medicationEmptyDescription =>
      'Tap add to set a schedule and track adherence.';

  @override
  String get medicationEmptyCta => 'Add medication';

  @override
  String get medicationStatusActive => 'Active';

  @override
  String get medicationStatusPaused => 'Paused';

  @override
  String get medicationStatusStopped => 'Stopped';

  @override
  String get medicationNoDoseTime => 'No dose time';

  @override
  String get reminderTitle => 'Today\'s reminders';

  @override
  String get reminderHeaderTitle => 'Today\'s schedule';

  @override
  String get reminderHeaderSubtitle => 'Prioritize doses due today';

  @override
  String get reminderEmptyTitle => 'Nothing to remind yet';

  @override
  String get reminderEmptyDescription =>
      'Add medications and times on the Medications screen.';

  @override
  String get reminderScheduleFlexible => 'Flexible time';

  @override
  String get reminderScheduleFixed => 'Scheduled';

  @override
  String get reminderNoDoseTime => 'No dose time';

  @override
  String get reminderNotifyTitle => 'Medication reminder';

  @override
  String get reminderNotifyNow => 'Notify now';

  @override
  String get reminderNow => 'now';

  @override
  String get reminderTaken => 'Taken';

  @override
  String get reminderLate => 'Late';

  @override
  String get reminderMissed => 'Missed';

  @override
  String reminderLoggedTaken(String name) {
    return 'Logged: $name taken on time';
  }

  @override
  String reminderLoggedLate(String name) {
    return 'Logged: $name taken late';
  }

  @override
  String reminderLoggedMissed(String name) {
    return 'Logged: missed $name';
  }

  @override
  String reminderLoggedGeneric(String name, String status) {
    return 'Logged $name: $status';
  }

  @override
  String get homeTimeForMedicine => 'TIME FOR YOUR MEDICINE';

  @override
  String homeScheduledFor(String time) {
    return 'Scheduled for $time';
  }

  @override
  String get homeMarkAsTaken => 'Mark as taken';

  @override
  String get homeSnooze => 'Snooze';

  @override
  String get homeSkip => 'Skip';

  @override
  String get homeUpcomingToday => 'UPCOMING TODAY';

  @override
  String get homeProTipTitle => 'Pro tip';

  @override
  String get homeProTipBody =>
      'Taking meds with meals can reduce stomach upset and build a steadier habit.';

  @override
  String homeAfterDoseTaken(String name) {
    return 'Marked taken: $name';
  }

  @override
  String homeAfterDoseSkipped(String name) {
    return 'Marked skipped: $name';
  }

  @override
  String get homeServerLogFailed =>
      'Saved on device; could not sync to server.';

  @override
  String get homeSyncFailed => 'Could not load medications from server.';

  @override
  String get homeQuickActionsTitle => 'Quick actions';

  @override
  String homeSubtitleDosageTime(String dosage, String time) {
    return '$dosage • $time';
  }

  @override
  String get homeEmptyTitle => 'No schedule yet';

  @override
  String get homeEmptyBody =>
      'Add meds via Scan or ask the AI assistant (saved on your device). Account sync may come later.';

  @override
  String get doseStatusTaken => 'TAKEN';

  @override
  String get doseStatusMissed => 'MISSED';

  @override
  String get doseStatusUpcoming => 'UPCOMING';

  @override
  String get doseStatusYesterday => 'Yesterday';

  @override
  String get scheduleSectionTitle => 'TODAY\'S SCHEDULE';

  @override
  String get scheduleViewCalendar => 'View calendar';

  @override
  String get scheduleAlreadyRecorded => 'Already recorded';

  @override
  String get scheduleMarkAsTaken => 'Mark as taken';

  @override
  String get scheduleReschedule => 'Reschedule';

  @override
  String get scheduleMarkTaken => 'Mark taken';

  @override
  String get adherenceTitle => 'Treatment adherence';

  @override
  String get adherenceNoData => 'No adherence data yet.';

  @override
  String adherenceTotalDoses(int days) {
    return 'Total doses ($days days)';
  }

  @override
  String get adherenceTakenLabel => 'Taken';

  @override
  String get adherenceMissedLabel => 'Missed';

  @override
  String get adherenceSkippedLabel => 'Skipped';

  @override
  String get adherenceLateLabel => 'Late';

  @override
  String get scanTitle => 'Scan prescription';

  @override
  String get scanTooltipDismiss => 'Dismiss';

  @override
  String get scanAnalyzing => 'AI is analyzing the prescription…';

  @override
  String get scanRetry => 'Try again';

  @override
  String get scanRetake => 'Retake photo';

  @override
  String get scanPickImage => 'Choose image';

  @override
  String scanPickImageError(String error) {
    return 'Could not pick image: $error';
  }

  @override
  String get scanEmptyTitle => 'AI prescription scan';

  @override
  String get scanEmptyBody =>
      'Take a photo or pick from your library. AI detects meds, dosage, and builds a schedule.';

  @override
  String get scanCapturePrescription => 'Capture prescription';

  @override
  String get scanFromGallery => 'Choose from library';

  @override
  String get scanResultTitle => 'Analysis result';

  @override
  String scanResultSaved(int count) {
    return 'Prescription saved ($count meds)';
  }

  @override
  String get scanLabelDoctor => 'Doctor';

  @override
  String get scanLabelPatient => 'Patient';

  @override
  String get scanLabelDate => 'Date';

  @override
  String scanMedsDetected(int count) {
    return 'Medications ($count detected)';
  }

  @override
  String get scanNoMedsFound => 'No medications detected. Try a clearer photo.';

  @override
  String get scanSchedulePrefix => 'Schedule: ';

  @override
  String get treatmentRetry => 'Retry';

  @override
  String get notificationChannelName => 'Medication reminders';

  @override
  String get notificationChannelDescription =>
      'Daily medication reminder notifications';

  @override
  String get aiAppBarTitle => 'MedIntel';

  @override
  String aiWelcomeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get aiWelcomeBody =>
      'Your agent can log doses, add meds, and take notes — stored on your device first (cloud sync later if enabled).';

  @override
  String get aiAssistantBadge => 'MEDINTEL ASSISTANT';

  @override
  String get aiComposerHint => 'Ask MedIntel anything…';

  @override
  String get aiConnectionError =>
      'Sorry, we couldn\'t connect. Please try again.';

  @override
  String get aiSuggestSectionApp => 'In the app';

  @override
  String get aiSuggestSectionKnowledge => 'Knowledge & lookup';

  @override
  String get aiSuggestSectionOther => 'Other';

  @override
  String get aiChatRotatingCaption => 'Ideas for you';

  @override
  String get aiChatRotatingFallback0 => 'How are you feeling today?';

  @override
  String get aiChatRotatingFallback1 =>
      'Try \"I just took my medication\" to log a dose, or ask about your meds.';

  @override
  String get aiChatRotatingFallback2 =>
      'New prescription? Scan it from the Scan tab, then keep chatting here.';

  @override
  String get quickScanTitle => 'Scan new prescription';

  @override
  String get quickScanSubtitle => 'Add meds with AI scanning';

  @override
  String get quickChipChat => 'AI chat';

  @override
  String get quickChipMedication => 'Medication';

  @override
  String get quickChipReminder => 'Reminder';

  @override
  String get adherenceHeroTodayProgress => 'TODAY\'S PROGRESS';

  @override
  String get adherenceHeroTakenToday => '  TAKEN TODAY';

  @override
  String get adherenceHeroEmptyHint => 'Add medications to start tracking.';

  @override
  String get adherenceHeroProgressHint =>
      'Great start — keep it up to hit today\'s goal.';

  @override
  String get careMonitoringLabel => 'MONITORING';

  @override
  String get careMedicationsTitle => 'Medications';

  @override
  String get careMedicationsEmpty =>
      'No medications in the database list yet. Add via Scan or AI Chat.';

  @override
  String get careTodayAdherence => 'Today\'s adherence';

  @override
  String careDosesLogged(int taken, int total) {
    return '$taken / $total DOSES LOGGED';
  }

  @override
  String get careDosesNoSchedule => 'NO DOSE SCHEDULE';

  @override
  String get careWeeklyScore => 'Weekly score';

  @override
  String get careRecentAlerts => 'Recent alerts';

  @override
  String get careAlertsEmpty => 'No recent alerts (from database data).';

  @override
  String get careVitalsDisconnected => 'NOT CONNECTED';

  @override
  String get careVitalsSubtitle => 'Vitals — device integration later';

  @override
  String get careOpenAiChat => 'OPEN AI CHAT';

  @override
  String get weeklyCaptionGood => 'STRONG PROGRESS';

  @override
  String get weeklyCaptionOk => 'STEADY';

  @override
  String get weeklyCaptionWatch => 'NEEDS ATTENTION';

  @override
  String get weeklyCaptionNoData => 'NO WEEKLY DATA';

  @override
  String get dashMedFallback => 'Medication';

  @override
  String get dashTimeInDay => 'During the day';

  @override
  String dashTimeAm(String hour, String minute) {
    return '$hour:$minute AM';
  }

  @override
  String dashTimePm(String hour12, String minute) {
    return '$hour12:$minute PM';
  }

  @override
  String get dashUserFallback => 'User';

  @override
  String dashAlertMissedTitle(String patientName) {
    return '$patientName missed / skipped a dose';
  }

  @override
  String dashAlertMissedSubtitle(String medName, String note) {
    return '$medName • today ($note)';
  }

  @override
  String get dashAlertCareNote => 'Care note';

  @override
  String get dashTodayLocalNote => 'database data';

  @override
  String get localDataTitle => 'Database data (JSON)';

  @override
  String get localDataRefresh => 'Refresh';

  @override
  String localDataRefreshNote(int seconds) {
    return 'Auto-refresh every ${seconds}s (reload database-sync / device cache state).';
  }

  @override
  String get authTitle => 'Auth';

  @override
  String get authBody => 'auth — JWT login';

  @override
  String get placeholderScanTitle => 'Scan prescription';

  @override
  String get placeholderScanBody => 'prescription_scan — camera + OCR';
}
