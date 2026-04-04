import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/vitalis_colors.dart';
import '../../core/widgets/vitalis_search_field.dart';
import 'data/home_demo_data.dart';
import 'widgets/adherence_hero_card.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/next_dose_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/today_schedule_section.dart';

/// Màn Home — tổng quan sức khỏe hàng ngày (Vitalis Clarity / Stitch design).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = homeDemoModel();

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
                AdherenceHeroCard(
                  adherenceFraction: model.adherenceFraction,
                  dosesTaken: model.dosesTaken,
                  dosesTotal: model.dosesTotal,
                ),
                const SizedBox(height: 20),
                if (model.nextDose != null) ...[
                  NextDoseCard(dose: model.nextDose!),
                  const SizedBox(height: 28),
                ],
                TodayScheduleSection(items: model.todaySchedule),
                const SizedBox(height: 28),
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
