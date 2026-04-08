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

  static Future<void> showMedicationReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    const android = AndroidNotificationDetails(
      'medintel_medication',
      'Nhắc uống thuốc',
      channelDescription: 'Thông báo nhắc uống thuốc hằng ngày',
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: android, iOS: ios),
    );
  }
}
