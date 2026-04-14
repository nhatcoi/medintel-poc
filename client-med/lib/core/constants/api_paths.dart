/// Centralized API path constants for cleaner repositories.
final class ApiPaths {
  ApiPaths._();

  static const String authRegister = '/api/v1/auth/register';
  static const String authRegisterPhone = '/api/v1/auth/register-phone';
  static const String authLoginPhone = '/api/v1/auth/login-phone';
  static const String authLogoutPhone = '/api/v1/auth/logout-phone';
  static const String authSessionMe = '/api/v1/auth/session/me';
  static const String authDeviceSetup = '/api/v1/auth/device-setup';

  static const String profileOnboarding = '/api/v1/profiles/onboarding';

  static const String chatMessage = '/api/v1/chat/message';
  static const String chatSuggestedQuestions = '/api/v1/chat/suggested-questions';
  static const String chatWelcomeHints = '/api/v1/chat/welcome-hints';
  static const String ragSearch = '/api/v1/rag/search';
  static const String medicalRecords = '/api/v1/medical-records/';
  static const String memory = '/api/v1/memory/';

  static const String treatmentMedications = '/api/v1/treatment/medications';
  static const String treatmentSchedules = '/api/v1/treatment/schedules';
  static const String treatmentLogs = '/api/v1/treatment/logs';
  static const String treatmentMedicationsLowStock = '/api/v1/treatment/medications/low-stock';
  static const String treatmentMedicationsSearch = '/api/v1/treatment/medications/search';
  static const String treatmentAdherenceSummary =
      '/api/v1/treatment/adherence/summary';
  static const String treatmentNextDose = '/api/v1/treatment/next-dose';
  static const String treatmentMissedDoseCheck =
      '/api/v1/treatment/missed-dose-check';

  static const String scanPrescription = '/api/v1/scan/prescription';
}
