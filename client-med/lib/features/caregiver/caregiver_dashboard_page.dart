import 'package:flutter/material.dart';

import 'data/caregiver_demo_data.dart';
import 'widgets/caregiver_top_bar.dart';
import 'widgets/medications_section.dart';
import 'widgets/monitoring_cards_block.dart';
import 'widgets/patient_monitoring_header.dart';
import 'widgets/recent_alerts_section.dart';
import '../../core/theme/vitalis_colors.dart';

/// **Caregiver View** — nội dung scroll; shell bọc SafeArea + bottom nav.
class CaregiverDashboardPage extends StatelessWidget {
  const CaregiverDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = caregiverDemoModel();

    return Scaffold(
      backgroundColor: VitalisColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CaregiverTopBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const SizedBox(height: 8),
                PatientMonitoringHeader(
                  patientName: model.patientName,
                  onCall: () {},
                  onMessage: () {},
                ),
                const SizedBox(height: 24),
                MonitoringCardsBlock(
                  adherenceFraction: model.adherenceFraction,
                  dosesTaken: model.dosesTaken,
                  dosesTotal: model.dosesTotal,
                  weeklyScoreFraction: model.weeklyScoreFraction,
                  weeklyCaption: model.weeklyCaption,
                  vitalsHeadline: model.vitalsHeadline,
                  vitalsSub: model.vitalsSub,
                ),
                const SizedBox(height: 28),
                MedicationsSection(
                  dateChipLabel: model.medicationsDateLabel,
                  items: model.medications,
                ),
                const SizedBox(height: 28),
                RecentAlertsSection(alerts: model.alerts),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
