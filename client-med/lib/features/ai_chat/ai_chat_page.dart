import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../core/theme/vitalis_colors.dart';
import '../treatment/data/treatment_provider.dart';
import '../../providers/local_medintel_provider.dart';
import '../../providers/providers.dart';
import '../../services/api_service.dart';
import 'data/ai_chat_models.dart';
import 'data/chat_repository.dart';
import 'widgets/ai_chat_composer.dart';
import 'widgets/ai_chat_message_tile.dart';
import 'widgets/ai_chat_quick_replies.dart';
import 'widgets/ai_chat_typing_indicator.dart';
import 'widgets/ai_chat_welcome_block.dart';

String? routeFromQuickPrompt(String prompt) {
  final p = prompt.trim().toLowerCase();
  if (p.isEmpty) return null;

  if (p.startsWith('open:') || p.startsWith('/open')) {
    if (p.contains('history')) return '/history';
    if (p.contains('home')) return '/home';
    if (p.contains('scan')) return '/scan';
    if (p.contains('care')) return '/care';
    if (p.contains('memory')) return '/memory';
    if (p.contains('medical')) return '/medical-records';
  }

  if (p.contains('lịch sử') || p.contains('history')) return '/history';
  if (p.contains('quét') || p.contains('scan')) return '/scan';
  if (p.contains('trang chủ') || p.contains('home')) return '/home';
  if (p.contains('chăm sóc') || p.contains('caregiver') || p.contains('care')) {
    return '/care';
  }
  return null;
}

class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  late final TextEditingController _composer;
  late final ScrollController _scroll;
  late final ChatRepository _repo;

  final List<AiChatItem> _messages = [];
  bool _isTyping = false;

  /// Nối tiếp phiên chat đã lưu trên server (POST /chat/message trả về).
  String? _chatSessionId;

  /// Gợi ý từ GET /chat/welcome-hints; null = chưa tải hoặc lỗi (dùng fallback l10n).
  List<String>? _welcomeHintsFromApi;
  List<SuggestedChatAction> _initialSuggestedActions = const [];
  String? _boundProfileId;
  _PendingDoseConfirmation? _pendingDoseConfirmation;
  _PendingScanConfirmation? _pendingScanConfirmation;
  int? _animatingMessageIndex;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _composer = TextEditingController();
    _scroll = ScrollController();
    _repo = ChatRepository(ApiService());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWelcomeHints();
      _loadSuggestedQuestions();
    });
  }

  Future<void> _loadWelcomeHints() async {
    final id = ref.read(activeProfileIdProvider);
    if (id == null || id.trim().isEmpty) return;
    final hints = await _repo.fetchWelcomeHints(id);
    if (!mounted) return;
    setState(() {
      _welcomeHintsFromApi = hints.isNotEmpty ? hints : null;
    });
  }

  Future<void> _loadSuggestedQuestions() async {
    final id = ref.read(activeProfileIdProvider);
    if (id == null || id.trim().isEmpty) return;
    final questions = await _repo.fetchSuggestedQuestions(id);
    if (!mounted) return;
    setState(() {
      _initialSuggestedActions = questions;
    });
  }

  List<String> _rotatingPhrases(AppLocalizations l10n) {
    if (_welcomeHintsFromApi != null && _welcomeHintsFromApi!.isNotEmpty) {
      return _welcomeHintsFromApi!;
    }
    return [
      l10n.aiChatRotatingFallback0,
      l10n.aiChatRotatingFallback1,
      l10n.aiChatRotatingFallback2,
    ];
  }

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;
    final hadPendingDose = _pendingDoseConfirmation != null;
    final isConfirmOrCancel = _isConfirmOrCancelText(trimmed);

    setState(() {
      _messages.add(AiChatUserTurn(body: trimmed, timeLabel: _nowLabel()));
      _isTyping = true;
    });
    _composer.clear();
    _scrollToBottom();

    try {
      final profileId = ref.read(activeProfileIdProvider);
      final hasProfile = profileId != null && profileId.isNotEmpty;

      final result = await _repo.sendMessage(
        trimmed,
        profileId: hasProfile ? profileId : null,
        sessionId: _chatSessionId,
        includeMedicationContext: hasProfile,
      );
      if (!mounted) return;

      if (result.sessionId != null && result.sessionId!.isNotEmpty) {
        _chatSessionId = result.sessionId;
      }

      // `log_dose` tool call can be a pre-confirm proposal.
      // Only apply non-write tool effects to local cache at this step.
      final executableTools = result.toolCalls
          .where(
            (tc) =>
                (tc['tool']?.toString().trim().toLowerCase() ?? '') !=
                'log_dose',
          )
          .toList(growable: false);
      final summaries = await ref
          .read(localMedintelProvider.notifier)
          .applyAgentToolCalls(executableTools);
      final pendingDose = _extractPendingDoseConfirmation(
        result.reply,
        result.toolCalls,
      );

      String? callout;
      if (summaries.isNotEmpty) {
        callout = summaries.join('\n');
      }

      setState(() {
        _isTyping = false;
        _messages.add(
          AiChatAssistantTurn(
            body: result.reply,
            timeLabel: _nowLabel(),
            suggestedActions: result.suggestedActions,
            callout: callout,
            toolSummaries: summaries,
          ),
        );
        _animatingMessageIndex = _messages.length - 1;
        _pendingDoseConfirmation = pendingDose;
      });
      if (hadPendingDose && isConfirmOrCancel && pendingDose == null) {
        await _reloadTreatmentData();
      }
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _isTyping = false;
        _messages.add(
          AiChatAssistantTurn(body: l10n.aiConnectionError, timeLabel: ''),
        );
      });
    }

    _scrollToBottom();
  }

  Future<void> _pickAndAnalyzeImage() async {
    if (_isTyping) return;
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;

    final profileId = ref.read(activeProfileIdProvider);
    setState(() {
      _messages.add(
        AiChatUserTurn(
          body: 'Đã tải ảnh toa thuốc: ${picked.name}',
          timeLabel: _nowLabel(),
        ),
      );
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final preview = await _repo.scanPrescriptionImage(
        picked,
        profileId: profileId,
        persist: false,
      );
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          AiChatAssistantTurn(
            body: _buildScanPreviewMessage(preview),
            timeLabel: _nowLabel(),
          ),
        );
        _animatingMessageIndex = _messages.length - 1;
        _pendingScanConfirmation = preview.looksLikePrescription
            ? _PendingScanConfirmation(image: picked)
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          AiChatAssistantTurn(
            body:
                'Mình chưa phân tích được ảnh này. Bạn hãy thử ảnh rõ nét hơn hoặc chụp toàn bộ đơn thuốc.',
            timeLabel: _nowLabel(),
          ),
        );
        _animatingMessageIndex = _messages.length - 1;
        _pendingScanConfirmation = null;
      });
    }
    _scrollToBottom();
  }

  Future<void> _confirmScannedPrescription() async {
    final pending = _pendingScanConfirmation;
    if (pending == null || _isTyping) return;
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null || profileId.trim().isEmpty) return;

    setState(() => _isTyping = true);
    try {
      final saved = await _repo.scanPrescriptionImage(
        pending.image,
        profileId: profileId,
        persist: true,
      );
      if (!mounted) return;
      await _reloadTreatmentData();
      final count = saved.medications.length;
      setState(() {
        _isTyping = false;
        _messages.add(
          AiChatAssistantTurn(
            body:
                'Mình đã thêm $count thuốc từ ảnh vào tủ thuốc và lịch uống mặc định của bạn.',
            timeLabel: _nowLabel(),
          ),
        );
        _animatingMessageIndex = _messages.length - 1;
        _pendingScanConfirmation = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          AiChatAssistantTurn(
            body: 'Lưu toa thuốc chưa thành công. Bạn thử lại giúp mình nhé.',
            timeLabel: _nowLabel(),
          ),
        );
        _animatingMessageIndex = _messages.length - 1;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    });
  }

  String _nowLabel() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool get _showQuickReplies {
    if (_isTyping || _messages.isEmpty) return false;
    final last = _messages.last;
    return last is AiChatAssistantTurn && last.suggestedActions.isNotEmpty;
  }

  List<SuggestedChatAction> get _lastSuggestedActions {
    if (_messages.isEmpty) return const [];
    final last = _messages.last;
    if (last is AiChatAssistantTurn) return last.suggestedActions;
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final currentProfileId = ref.watch(activeProfileIdProvider);
    if (currentProfileId != _boundProfileId) {
      _boundProfileId = currentProfileId;
      _chatSessionId = null;
      _messages.clear();
      _pendingDoseConfirmation = null;
      _pendingScanConfirmation = null;
      _animatingMessageIndex = null;
      _welcomeHintsFromApi = null;
      _initialSuggestedActions = const [];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadWelcomeHints();
        _loadSuggestedQuestions();
      });
    }
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: VitalisColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                AiChatWelcomeBlock(
                  showTypewriter: _messages.isEmpty,
                  rotatingPhrases: _rotatingPhrases(l10n),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < _messages.length; i++) ...[
                        if (i > 0) const SizedBox(height: 20),
                        AiChatMessageTile(
                          item: _messages[i],
                          animate: i == _animatingMessageIndex,
                          onAnimationCompleted: i == _animatingMessageIndex
                              ? () {
                                  if (!mounted) return;
                                  setState(() => _animatingMessageIndex = null);
                                }
                              : null,
                        ),
                      ],
                      if (_isTyping) ...[
                        const SizedBox(height: 20),
                        const AiChatTypingIndicator(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (_showQuickReplies)
                  AiChatQuickReplies(
                    actions: _lastSuggestedActions,
                    onSelected: _handleQuickAction,
                  ),
                if (!_showQuickReplies &&
                    _messages.isEmpty &&
                    _initialSuggestedActions.isNotEmpty)
                  AiChatQuickReplies(
                    actions: _initialSuggestedActions,
                    onSelected: _handleQuickAction,
                  ),
              ],
            ),
          ),
          if (_pendingDoseConfirmation != null)
            _DoseConfirmBar(
              medicationName: _pendingDoseConfirmation!.medicationName,
              enabled: !_isTyping,
              onConfirm: () => _sendMessage('xác nhận'),
              onCancel: () => _sendMessage('hủy'),
            ),
          if (_pendingScanConfirmation != null)
            _ScanConfirmBar(
              enabled: !_isTyping,
              onConfirm: _confirmScannedPrescription,
              onCancel: () => setState(() => _pendingScanConfirmation = null),
            ),
          AiChatComposer(
            controller: _composer,
            enabled: !_isTyping,
            onSend: () => _sendMessage(_composer.text),
            onAttachImage: _pickAndAnalyzeImage,
          ),
        ],
      ),
    );
  }

  void _handleQuickAction(String prompt) {
    if (_tryNavigateFromPrompt(prompt)) return;
    _sendMessage(prompt);
  }

  bool _tryNavigateFromPrompt(String prompt) {
    final route = routeFromQuickPrompt(prompt);
    if (route == null) return false;
    final routeLabel = switch (route) {
      '/history' => 'Lịch sử',
      '/home' => 'Trang chủ',
      '/scan' => 'Quét đơn',
      '/care' => 'Chăm sóc',
      '/memory' => 'Memory',
      '/medical-records' => 'Hồ sơ bệnh án',
      _ => route,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang mở: $routeLabel'),
        duration: const Duration(milliseconds: 900),
      ),
    );
    context.go(route);
    return true;
  }

  bool _isConfirmOrCancelText(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty) return false;
    const yesWords = {'xác nhận', 'xac nhan', 'ok', 'oke', 'đồng ý', 'dong y'};
    const noWords = {
      'hủy',
      'huy',
      'không',
      'khong',
      'dừng',
      'dung',
      'thôi',
      'thoi',
    };
    return yesWords.any(t.contains) || noWords.any(t.contains);
  }

  Future<void> _reloadTreatmentData() async {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null || profileId.trim().isEmpty) return;
    await ref.read(treatmentProvider.notifier).loadHomeSchedule(profileId);
    await ref.read(treatmentProvider.notifier).loadSummary(profileId);
  }

  String _buildScanPreviewMessage(ScanPrescriptionPreviewResult preview) {
    if (!preview.looksLikePrescription) {
      return 'Mình đã phân tích ảnh nhưng chưa thấy cấu trúc đơn thuốc rõ ràng. Bạn có thể gửi ảnh toa rõ hơn không?';
    }
    final b = StringBuffer();
    b.writeln('Mình phát hiện đây có thể là đơn thuốc.');
    if (preview.diseaseName.trim().isNotEmpty) {
      b.writeln('Chẩn đoán: ${preview.diseaseName.trim()}');
    }
    b.writeln('\nThuốc trong đơn:');
    for (final med in preview.medications) {
      final extras = <String>[];
      if ((med.dosage ?? '').trim().isNotEmpty) extras.add(med.dosage!.trim());
      if ((med.frequency ?? '').trim().isNotEmpty) {
        extras.add(med.frequency!.trim());
      }
      if (med.times.isNotEmpty) extras.add('giờ: ${med.times.join(', ')}');
      if (extras.isEmpty) {
        b.writeln('- ${med.name}');
      } else {
        b.writeln('- ${med.name} (${extras.join(' | ')})');
      }
    }
    b.writeln(
      '\nBạn có muốn thêm các thuốc này vào tủ thuốc và lịch uống không?',
    );
    return b.toString();
  }

  _PendingDoseConfirmation? _extractPendingDoseConfirmation(
    String reply,
    List<Map<String, dynamic>> toolCalls,
  ) {
    if (!reply.toLowerCase().contains('xác nhận')) return null;
    for (final tc in toolCalls) {
      final tool = tc['tool']?.toString().trim().toLowerCase();
      if (tool != 'log_dose') continue;
      final args = tc['args'];
      if (args is! Map) continue;
      final med = args['medication_name']?.toString().trim();
      return _PendingDoseConfirmation(medicationName: med ?? 'thuốc này');
    }
    return null;
  }
}

class _PendingDoseConfirmation {
  const _PendingDoseConfirmation({required this.medicationName});

  final String medicationName;
}

class _PendingScanConfirmation {
  const _PendingScanConfirmation({required this.image});

  final XFile image;
}

class _DoseConfirmBar extends StatelessWidget {
  const _DoseConfirmBar({
    required this.medicationName,
    required this.enabled,
    required this.onConfirm,
    required this.onCancel,
  });

  final String medicationName;
  final bool enabled;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VitalisColors.surfaceContainerLowest,
            VitalisColors.surfaceContainerLow,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: VitalisColors.outlineVariantBase.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: VitalisColors.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  size: 16,
                  color: VitalisColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Xác nhận uống thuốc',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: VitalisColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn đã uống $medicationName chưa?',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.icon(
                onPressed: enabled ? onConfirm : null,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Đã uống'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: enabled ? onCancel : null,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Chưa uống / Hủy'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScanConfirmBar extends StatelessWidget {
  const _ScanConfirmBar({
    required this.enabled,
    required this.onConfirm,
    required this.onCancel,
  });

  final bool enabled;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VitalisColors.surfaceContainerLowest,
            VitalisColors.surfaceContainerLow,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: VitalisColors.outlineVariantBase.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: VitalisColors.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: VitalisColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Đơn thuốc đã phân tích',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: VitalisColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn muốn thêm các thuốc này vào tủ thuốc và lịch uống?',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: enabled ? onConfirm : null,
                  icon: const Icon(
                    Icons.playlist_add_check_circle_outlined,
                    size: 18,
                  ),
                  label: const Text('Thêm vào tủ thuốc'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: enabled ? onCancel : null,
                child: const Text('Không thêm'),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Bạn có thể xem lại danh sách thuốc trước khi xác nhận.',
              style: textTheme.bodySmall?.copyWith(
                color: VitalisColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
