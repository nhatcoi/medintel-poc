import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../core/theme/vitalis_colors.dart';
import '../../data/dashboard_from_local.dart';
import '../../data/local_medintel_state.dart';
import '../../providers/local_medintel_provider.dart';
import '../../providers/providers.dart';
import 'data/caregiver_profiles_state.dart';
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
    final primaryName = auth.user?.fullName?.trim().isNotEmpty == true
        ? auth.user!.fullName!.trim()
        : l10n.genericYou;
    ref.read(caregiverProfilesProvider.notifier).syncPrimaryProfile(
          displayName: primaryName,
          profileId: auth.user?.id ?? '',
          localState: local,
        );
    final profilesState = ref.watch(caregiverProfilesProvider);
    final selectedProfile = profilesState.selectedProfile;
    final selectedLocal = selectedProfile?.localState ?? LocalMedintelState.empty;
    final patientName = selectedProfile?.displayName ?? primaryName;
    final model = DashboardFromLocal.buildCaregiver(selectedLocal, patientName, l10n);

    return Scaffold(
      backgroundColor: VitalisColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CaregiverTopBar(displayName: patientName),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const SizedBox(height: 8),
                _ManagedProfilesSection(
                  profilesState: profilesState,
                  onSelected: (id) {
                    ref.read(caregiverProfilesProvider.notifier).selectProfile(id);
                  },
                  onAdd: () => _showAddProfileSheet(context, ref),
                ),
                const SizedBox(height: 16),
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

  Future<void> _showAddProfileSheet(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final insets = MediaQuery.viewInsetsOf(ctx);
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, insets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên profile',
                  hintText: 'Ví dụ: Bé Na',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: relationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mối quan hệ',
                  hintText: 'Ví dụ: Con gái',
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Thêm profile'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (ok != true) return;
    final name = nameCtrl.text.trim();
    final relation = relationCtrl.text.trim();
    if (name.isEmpty) return;
    final created = await ref.read(authRepositoryProvider).createOnboardingProfile(
          fullName: name,
          role: 'patient',
        );
    if (created.profileId.isEmpty) return;
    await ref.read(caregiverProfilesProvider.notifier).addProfile(
          profileId: created.profileId,
          displayName: name,
          relationshipLabel: relation,
        );
  }
}

class _ManagedProfilesSection extends StatelessWidget {
  const _ManagedProfilesSection({
    required this.profilesState,
    required this.onSelected,
    required this.onAdd,
  });

  final CareProfilesState profilesState;
  final ValueChanged<String> onSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final selectedId = profilesState.selectedProfileId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile quản lý',
            style: TextStyle(
              color: VitalisColors.caregiverHeroBlue,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final p in profilesState.profiles) ...[
                  _ProfileAvatarItem(
                    name: p.displayName,
                    relation: p.relationshipLabel,
                    selected: (selectedId == null || selectedId.isEmpty)
                        ? p.id == 'primary'
                        : selectedId == p.id,
                    onTap: () => onSelected(p.id),
                  ),
                  const SizedBox(width: 12),
                ],
                OutlinedButton(
                  onPressed: onAdd,
                  style: OutlinedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatarItem extends StatelessWidget {
  const _ProfileAvatarItem({
    required this.name,
    required this.relation,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String relation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: selected ? 24 : 22,
            backgroundColor:
                selected ? VitalisColors.primary : VitalisColors.surfaceContainerLow,
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : VitalisColors.caregiverHeroBlue,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 80,
            child: Text(
              relation,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? VitalisColors.primary : VitalisColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
