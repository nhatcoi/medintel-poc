import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Nhắc uống thuốc cục bộ — triển khai đầy đủ schedule theo [MedicationSchedules] sau.
final class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  static FlutterLocalNotificationsPlugin get plugin => _plugin;
}
