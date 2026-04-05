import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/vitalis_colors.dart';
import '../../core/widgets/vitalis_search_field.dart';
import '../../data/dashboard_from_local.dart';
import '../../providers/local_medintel_provider.dart';
import '../../providers/providers.dart';
import 'widgets/adherence_hero_card.dart';
import 'widgets/home_empty_state.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/next_dose_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/today_schedule_section.dart';

/// Màn Home — dữ liệu từ thuốc & log liều cục bộ + tên user đã setup.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = ref.watch(localMedintelProvider);
    final auth = ref.watch(authProvider);
    final userName = auth.user?.fullName?.trim().isNotEmpty == true
        ? auth.user!.fullName!.trim()
        : 'Bạn';
    final model = DashboardFromLocal.buildHome(local, userName);
    final hasMeds = model.todaySchedule.isNotEmpty;

    return Scaffold(
      backgroundColor: VitalisColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeTopBar(
            userName: model.userName,
            onSettingsTap: () => context.pushNamed('settings'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: VitalisSearchField(hintText: 'Tìm thuốc, bác sĩ, chức năng…'),
                ),
                const SizedBox(height: 24),
                if (!hasMeds) ...[
                  const HomeEmptyState(),
                  const SizedBox(height: 24),
                ],
                AdherenceHeroCard(
                  adherenceFraction: model.adherenceFraction,
                  dosesTaken: model.dosesTaken,
                  dosesTotal: model.dosesTotal,
                ),
                const SizedBox(height: 20),
                if (hasMeds && model.nextDose != null) ...[
                  NextDoseCard(dose: model.nextDose!),
                  const SizedBox(height: 28),
                ],
                if (hasMeds) TodayScheduleSection(items: model.todaySchedule),
                if (hasMeds) const SizedBox(height: 28),
                QuickActionsRow(
                  onScanTap: () => context.goNamed('scan'),
                  onChatTap: () => context.goNamed('ai'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
