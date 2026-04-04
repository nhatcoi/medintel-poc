import 'package:flutter/material.dart';

/// Model tĩnh cho UI — sau nối API.
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
  });

  final bool isUrgent;
  final String title;
  final String subtitle;
  final String? actionLabel;
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

CaregiverDashboardUiModel caregiverDemoModel() {
  return const CaregiverDashboardUiModel(
    patientName: 'John Doe',
    adherenceFraction: 0.75,
    dosesTaken: 3,
    dosesTotal: 4,
    weeklyScoreFraction: 0.92,
    weeklyCaption: 'EXCELLENT PROGRESS',
    vitalsHeadline: 'STABLE',
    vitalsSub: 'Vitals Sync',
    medicationsDateLabel: 'Today, Oct 24',
    medications: [
      MedicationDoseItem(
        name: 'Lisinopril',
        timeLabel: '8:00 AM',
        dosageLabel: '10mg / Tablet',
        status: MedicationDoseStatus.taken,
      ),
      MedicationDoseItem(
        name: 'Metformin',
        timeLabel: '1:00 PM',
        dosageLabel: '500mg / Tablet',
        status: MedicationDoseStatus.missed,
      ),
      MedicationDoseItem(
        name: 'Atorvastatin',
        timeLabel: '9:00 PM',
        dosageLabel: '20mg / Tablet',
        status: MedicationDoseStatus.upcoming,
      ),
    ],
    alerts: [
      CareAlertItem(
        isUrgent: true,
        title: 'John missed his morning dose',
        subtitle: '2 hours ago • Metformin (1:00 PM)',
        actionLabel: 'SEND REMINDER',
      ),
      CareAlertItem(
        isUrgent: false,
        title: 'Medication refill confirmed',
        subtitle: 'Yesterday • Lisinopril stock updated',
      ),
    ],
  );
}
