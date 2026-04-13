import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

/// Nhắc uống thuốc trên thiết bị (theo lịch đồng bộ database) — triển khai đầy đủ schedule theo [MedicationSchedules] sau.
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
    final l10n = lookupAppLocalizations(const Locale('vi'));
    final android = AndroidNotificationDetails(
      'medintel_medication',
      l10n.notificationChannelName,
      channelDescription: l10n.notificationChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: android, iOS: ios),
    );
  }
}
