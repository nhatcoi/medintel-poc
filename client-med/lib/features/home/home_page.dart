import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/vitalis_colors.dart';
import '../../data/dashboard_from_local.dart';
import '../../providers/local_medintel_provider.dart';
import '../../providers/providers.dart';
import 'data/home_ui_model.dart';
import 'widgets/adherence_hero_card.dart';
import 'widgets/home_empty_state.dart';
import 'widgets/home_top_bar.dart';

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
                if (!hasMeds) ...[
                  const HomeEmptyState(),
                  const SizedBox(height: 20),
                ],
                AdherenceHeroCard(
                  adherenceFraction: model.adherenceFraction,
                  dosesTaken: model.dosesTaken,
                  dosesTotal: model.dosesTotal,
                ),
                const SizedBox(height: 18),
                if (hasMeds) _CurrentDoseCard(dose: model.nextDose ?? model.todaySchedule.first),
                if (hasMeds) const SizedBox(height: 18),
                if (hasMeds) _UpcomingTodayList(items: model.todaySchedule),
                if (hasMeds) const SizedBox(height: 16),
                const _ProTipCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentDoseCard extends StatelessWidget {
  const _CurrentDoseCard({required this.dose});

  final HomeDoseItem dose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TIME FOR YOUR MEDICINE',
                style: text.headlineSmall?.copyWith(
                  color: const Color(0xFF2D333A),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Scheduled for ${dose.timeLabel}',
                style: text.bodyMedium?.copyWith(color: VitalisColors.neutral),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dose.name,
                            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dose.dosageLabel,
                            style: text.titleSmall?.copyWith(color: VitalisColors.primary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEF8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.medication_outlined, color: VitalisColors.primary, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.pushNamed('reminder'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as Taken'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => context.pushNamed('reminder'),
                      child: const Text('Snooze'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => context.pushNamed('reminder'),
                      child: const Text('Skip'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingTodayList extends StatelessWidget {
  const _UpcomingTodayList({required this.items});

  final List<HomeDoseItem> items;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final upcomingItems = items.where((e) => e.status == HomeDoseStatus.upcoming).toList();
    if (upcomingItems.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPCOMING TODAY',
            style: text.labelMedium?.copyWith(
              color: VitalisColors.neutral,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in upcomingItems.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(item.icon, color: VitalisColors.primary, size: 18),
                  ),
                  title: Text(item.name, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  subtitle: Text('${item.dosageLabel} • ${item.timeLabel}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.pushNamed('reminder'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProTipCard extends StatelessWidget {
  const _ProTipCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFDDF3E3),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pro Tip',
                      style: text.titleSmall?.copyWith(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Uống thuốc cùng bữa ăn giúp giảm kích ứng dạ dày và dễ duy trì thói quen hơn.',
                      style: text.bodySmall?.copyWith(color: const Color(0xFF336B46)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
