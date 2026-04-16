import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../core/theme/vitalis_colors.dart';
import '../../data/dashboard_from_local.dart';
import '../../data/local_medintel_state.dart';
import '../../providers/local_medintel_provider.dart';
import '../../providers/providers.dart';
import '../treatment/data/treatment_models.dart';
import '../treatment/data/treatment_provider.dart';
import 'data/caregiver_profiles_state.dart';
import 'data/drug_interaction_models.dart';
import '../treatment/data/notification_provider.dart';
import 'data/caregiver_ui_model.dart';
import 'data/drug_interaction_provider.dart';
import 'widgets/caregiver_top_bar.dart';
import 'widgets/com_b_insight_card.dart';
import 'widgets/drug_interaction_section.dart';
import 'widgets/interactive_warnings_section.dart';
import 'widgets/medications_section.dart';
import 'widgets/monitoring_cards_block.dart';
import 'widgets/patient_monitoring_header.dart';
import 'widgets/recent_alerts_section.dart';

class CaregiverDashboardPage extends ConsumerStatefulWidget {
  const CaregiverDashboardPage({super.key});

  @override
  ConsumerState<CaregiverDashboardPage> createState() =>
      _CaregiverDashboardPageState();
}

class _CaregiverDashboardPageState
    extends ConsumerState<CaregiverDashboardPage> {
  String? _boundProfileId;
  Timer? _notifTimer;

  @override
  void initState() {
    super.initState();
    // Fetch notifications on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
    // Poll for new notifications every 15 seconds for "live" feel
    _notifTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        ref.read(notificationProvider.notifier).fetchNotifications();
      }
    });
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }

  Future<void> _reloadForActiveProfile() async {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;
    await ref.read(treatmentProvider.notifier).loadHomeSchedule(profileId);
    await ref.read(treatmentProvider.notifier).loadSummary(profileId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final local = ref.watch(localMedintelProvider);
    final auth = ref.watch(authProvider);
    final primaryName = auth.user?.fullName?.trim().isNotEmpty == true
        ? auth.user!.fullName!.trim()
        : l10n.genericYou;
    final authProfileId = auth.user?.id ?? '';

    // Sync current profile to management list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(caregiverProfilesProvider.notifier).syncPrimaryProfile(
            displayName: primaryName,
            profileId: authProfileId,
            localState: local,
          );
    });

    final activeProfileId = ref.watch(activeProfileIdProvider);
    if (activeProfileId != _boundProfileId) {
      _boundProfileId = activeProfileId;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _reloadForActiveProfile(),
      );
    }

    final profilesState = ref.watch(caregiverProfilesProvider);
    final selectedProfile = profilesState.selectedProfile;
    final treatment = ref.watch(treatmentProvider);
    final selectedLocal = _localFromTreatment(
      items: treatment.items,
      logs: treatment.logs,
    );
    final patientName = selectedProfile?.displayName ?? primaryName;
    final model = DashboardFromLocal.buildCaregiver(
      selectedLocal,
      patientName,
      l10n,
    );

    final comB = computeComBScore(
      meds: treatment.items,
      schedules: treatment.schedules,
      logs: treatment.logs,
      missedDoses: treatment.missedDoses,
      summary7: treatment.summary,
    );
    final warnings = deriveWarnings(
      meds: treatment.items,
      schedules: treatment.schedules,
      missedDoses: treatment.missedDoses,
      nextDose: treatment.nextDose,
      summary7: treatment.summary,
    );

    final interactionState = ref.watch(drugInteractionProvider);
    final activeDrugNames = treatment.items
        .where((m) => (m.status ?? 'active').toLowerCase() == 'active')
        .map((m) => m.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    final notificationState = ref.watch(notificationProvider);

    // Listen for new notifications to show a floating snackbar pop-up
    ref.listen(notificationProvider, (previous, next) {
      if (previous != null && next.items.length > previous.items.length) {
        final newNotif = next.items.first;
        debugPrint('🔔 [NOTIFICATION RECEIVED] ${newNotif.title}');
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.notifications_active, color: VitalisColors.primary),
                const SizedBox(width: 8),
                Text(newNotif.title),
              ],
            ),
            content: Text(newNotif.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.goNamed('ai');
                },
                child: const Text('Xem chi tiết'),
              ),
            ],
          ),
        );
      }
    });

    final List<CareAlertItem> combinedAlerts = [
      ...notificationState.items.map(
        (n) => CareAlertItem(
          isUrgent: n.type == 'medication_missed',
          title: n.title,
          subtitle: n.message,
          actionLabel: 'Hành động',
          opensAiChat: true,
        ),
      ),
      ...model.alerts,
    ];

    return Scaffold(
      backgroundColor: VitalisColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await _reloadForActiveProfile();
          await ref.read(notificationProvider.notifier).fetchNotifications();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CaregiverTopBar(displayName: patientName),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 60),
                children: [
                  const SizedBox(height: 8),
                  _ManagedProfilesSection(
                    profilesState: profilesState,
                    onSelected: (id) {
                      ref
                          .read(caregiverProfilesProvider.notifier)
                          .selectProfile(id);
                    },
                    onAdd: () => _showAddProfileSheet(context, ref),
                  ),
                  const SizedBox(height: 16),
                  PatientMonitoringHeader(
                    patientName: patientName,
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
                  const SizedBox(height: 20),
                  DrugInteractionSection(
                    loading: interactionState.loading,
                    pairs: interactionState.pairs,
                    error: interactionState.error,
                    onRefresh: () => ref
                        .read(drugInteractionProvider.notifier)
                        .refresh(activeDrugNames),
                    onAskAi: (pair) => _askAiAboutInteraction(context, pair),
                  ),
                  const SizedBox(height: 20),
                  InteractiveWarningsSection(
                    warnings: warnings,
                    onAction: (w) => _handleWarningAction(context, w),
                  ),
                  const SizedBox(height: 20),
                  ComBInsightCard(score: comB),
                  const SizedBox(height: 28),
                  MedicationsSection(
                    dateChipLabel: model.medicationsDateLabel,
                    items: model.medications,
                  ),
                  const SizedBox(height: 28),
                  RecentAlertsSection(
                    alerts: combinedAlerts,
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
      ),
    );
  }

  Future<void> _handleWarningAction(
    BuildContext context,
    CareWarning warning,
  ) async {
    final profileId = ref.read(activeProfileIdProvider);
    switch (warning.action) {
      case WarningAction.logTaken:
        if (profileId == null ||
            profileId.isEmpty ||
            warning.medicationId == null) {
          return;
        }
        await ref
            .read(treatmentProvider.notifier)
            .logDose(
              profileId: profileId,
              medicationId: warning.medicationId!,
              status: 'taken',
              scheduledTime: warning.scheduledTime,
              scheduledDate: warning.scheduledDatetime?.toLocal(),
            );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Đã ghi nhận liều thuốc.'),
          ),
        );
        break;
      case WarningAction.openChat:
        if (!context.mounted) return;
        context.goNamed('ai');
        break;
      case WarningAction.openCabinet:
        if (!context.mounted) return;
        context.goNamed('cabinet');
        break;
      case WarningAction.openSchedule:
        if (!context.mounted) return;
        context.goNamed('cabinet');
        break;
    }
  }

  void _askAiAboutInteraction(BuildContext context, DrugInteractionPair pair) {
    context.goNamed('ai');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Hỏi AI về tương tác ${pair.drugA} × ${pair.drugB}…'),
      ),
    );
  }

  Future<void> _showAddProfileSheet(BuildContext context, WidgetRef ref) async {
    final phoneCtrl = TextEditingController();
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
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại bệnh nhân',
                  hintText: 'Ví dụ: 0987654321',
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
                  child: const Text('Thêm người bệnh'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (ok != true) return;
    final phone = phoneCtrl.text.trim();
    final relation = relationCtrl.text.trim();
    if (phone.isEmpty) return;

    final authId = ref.read(authProvider).user?.id ?? '';
    if (authId.isEmpty) return;

    try {
      final api = ref.read(apiServiceProvider);

      final profileRes = await api.client.get('/api/v1/profiles/phone/$phone');
      final foundProfileId = profileRes.data['profile_id'];
      final patientName = profileRes.data['full_name'] ?? 'Bệnh nhân';

      if (foundProfileId == null || foundProfileId.isEmpty) {
        throw Exception("Profile not found");
      }

      final groupRes = await api.client.post(
        '/api/v1/care/groups',
        data: {
          'group_name': 'Nhóm chăm sóc $patientName',
          'description': relation,
          'created_by_profile_id': authId,
        },
      );
      final groupId = groupRes.data['group_id'];

      await api.client.post(
        '/api/v1/care/group-patients',
        data: {
          'group_id': groupId,
          'patient_id': foundProfileId,
          'added_by_profile_id': authId,
          'consent_status': 'granted',
        },
      );

      await api.client.post(
        '/api/v1/care/group-members',
        data: {'group_id': groupId, 'profile_id': authId, 'role': 'caregiver'},
      );

      await ref
          .read(caregiverProfilesProvider.notifier)
          .addProfile(
            profileId: foundProfileId,
            displayName: patientName,
            relationshipLabel: relation,
          );
    } catch (e) {
      debugPrint("Care Group Setup Failed: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Người dùng không tồn tại hoặc có lỗi xảy ra!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  LocalMedintelState _localFromTreatment({
    required List<MedicationItem> items,
    required List<MedicationLogItem> logs,
  }) {
    final meds = items
        .map(
          (m) => LocalMedication(
            id: m.medicationId,
            name: m.name,
            dosageLabel: m.dosage,
            scheduleHint: m.scheduleTimes.isNotEmpty
                ? m.scheduleTimes.join(', ')
                : null,
          ),
        )
        .toList();
    final doseLogs = logs
        .map(
          (l) => LocalDoseLog(
            id: l.logId,
            medicationName: l.medicationName,
            status: l.status,
            recordedAtIso: (l.actualDatetime ?? l.scheduledDatetime)
                .toIso8601String(),
            note: l.notes,
          ),
        )
        .toList();
    return LocalMedintelState(medications: meds, doseLogs: doseLogs);
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
            backgroundColor: selected
                ? VitalisColors.primary
                : VitalisColors.surfaceContainerLow,
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: selected
                    ? Colors.white
                    : VitalisColors.caregiverHeroBlue,
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
                color: selected
                    ? VitalisColors.primary
                    : VitalisColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
