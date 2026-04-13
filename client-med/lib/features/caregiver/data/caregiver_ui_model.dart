import 'package:flutter/material.dart';

enum MedicationDoseStatus { taken, missed, upcoming }

@immutable
class MedicationDoseItem {
  const MedicationDoseItem({
    required this.name,
    required this.timeLabel,
    required this.dosageLabel,
    required this.status,
  });

  final String name;
  final String timeLabel;
  final String dosageLabel;
  final MedicationDoseStatus status;
}

@immutable
class CareAlertItem {
  const CareAlertItem({
    required this.isUrgent,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.opensAiChat = false,
  });

  final bool isUrgent;
  final String title;
  final String subtitle;
  final String? actionLabel;
  /// true → mở tab AI Chat (không so khớp chuỗi đã dịch).
  final bool opensAiChat;
}

@immutable
class CaregiverDashboardUiModel {
  const CaregiverDashboardUiModel({
    required this.patientName,
    required this.adherenceFraction,
    required this.dosesTaken,
    required this.dosesTotal,
    required this.weeklyScoreFraction,
    required this.weeklyCaption,
    required this.vitalsHeadline,
    required this.vitalsSub,
    required this.medicationsDateLabel,
    required this.medications,
    required this.alerts,
  });

  final String patientName;
  final double adherenceFraction;
  final int dosesTaken;
  final int dosesTotal;
  final double weeklyScoreFraction;
  final String weeklyCaption;
  final String vitalsHeadline;
  final String vitalsSub;
  final String medicationsDateLabel;
  final List<MedicationDoseItem> medications;
  final List<CareAlertItem> alerts;
}
