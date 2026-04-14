/// Hằng số ứng dụng (API, timeout, khóa lưu trữ).
final class AppConstants {
  AppConstants._();

  static const String appName = 'MedIntel';

  /// Đổi theo môi trường (dev/staging/prod).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const Duration apiTimeout = Duration(seconds: 30);

  /// Gửi kèm multipart `/scan/prescription` nếu có; nếu trống, server dùng `DEFAULT_PRESCRIPTION_USER_ID`.
  static const String prescriptionUserId = String.fromEnvironment(
    'PRESCRIPTION_USER_ID',
    defaultValue: '',
  );
}
