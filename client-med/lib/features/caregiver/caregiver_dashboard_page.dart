import 'package:flutter/material.dart';

import 'data/caregiver_demo_data.dart';
import 'widgets/caregiver_bottom_nav.dart';
import 'widgets/caregiver_top_bar.dart';
import 'widgets/medications_section.dart';
import 'widgets/monitoring_cards_block.dart';
import 'widgets/patient_monitoring_header.dart';
import 'widgets/recent_alerts_section.dart';
import '../../core/theme/vitalis_colors.dart';

/// **Caregiver View** — màn giám sát bệnh nhân (mock + design system Vitalis).
class CaregiverDashboardPage extends StatefulWidget {
  const CaregiverDashboardPage({super.key});

  @override
  State<CaregiverDashboardPage> createState() => _CaregiverDashboardPageState();
}

class _CaregiverDashboardPageState extends State<CaregiverDashboardPage> {
  late final CaregiverDashboardUiModel _model;
  int _navIndex = CaregiverBottomNav.indexCare;

  @override
  void initState() {
    super.initState();
    _model = caregiverDemoModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VitalisColors.background,
      appBar: const CaregiverTopBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SizedBox(height: 8),
          PatientMonitoringHeader(
            patientName: _model.patientName,
            onCall: () {},
            onMessage: () {},
          ),
          const SizedBox(height: 24),
          MonitoringCardsBlock(
            adherenceFraction: _model.adherenceFraction,
            dosesTaken: _model.dosesTaken,
            dosesTotal: _model.dosesTotal,
            weeklyScoreFraction: _model.weeklyScoreFraction,
            weeklyCaption: _model.weeklyCaption,
            vitalsHeadline: _model.vitalsHeadline,
            vitalsSub: _model.vitalsSub,
          ),
          const SizedBox(height: 28),
          MedicationsSection(
            dateChipLabel: _model.medicationsDateLabel,
            items: _model.medications,
          ),
          const SizedBox(height: 28),
          RecentAlertsSection(alerts: _model.alerts),
        ],
      ),
      bottomNavigationBar: CaregiverBottomNav(
        currentIndex: _navIndex,
        onSelect: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}
