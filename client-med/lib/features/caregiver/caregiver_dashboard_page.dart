import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../core/theme/vitalis_colors.dart';
import '../../data/dashboard_from_local.dart';
import '../../providers/local_medintel_provider.dart';
import '../../providers/providers.dart';
import 'widgets/caregiver_top_bar.dart';
import 'widgets/medications_section.dart';
import 'widgets/monitoring_cards_block.dart';
import 'widgets/patient_monitoring_header.dart';
import 'widgets/recent_alerts_section.dart';

/// **Care** — theo dõi từ dữ liệu database / cache (cùng nguồn với Home); không dùng mẫu John Doe.
class CaregiverDashboardPage extends ConsumerWidget {
  const CaregiverDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final local = ref.watch(localMedintelProvider);
    final auth = ref.watch(authProvider);
    final patientName = auth.user?.fullName?.trim().isNotEmpty == true
        ? auth.user!.fullName!.trim()
        : l10n.genericYou;
    final model = DashboardFromLocal.buildCaregiver(local, patientName, l10n);

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
                RecentAlertsSection(
                  alerts: model.alerts,
                  onActionTap: (alert) {
                    if (alert.opensAiChat) {
                      context.goNamed('ai');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
