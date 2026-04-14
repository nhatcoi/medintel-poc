import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../core/theme/vitalis_colors.dart';
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
  if (p.contains('chăm sóc') || p.contains('caregiver') || p.contains('care')) return '/care';
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

      final summaries =
          await ref.read(localMedintelProvider.notifier).applyAgentToolCalls(result.toolCalls);

      String? callout;
      if (summaries.isNotEmpty) {
        callout = summaries.join('\n');
      }

      setState(() {
        _isTyping = false;
        _messages.add(AiChatAssistantTurn(
          body: result.reply,
          timeLabel: _nowLabel(),
          suggestedActions: result.suggestedActions,
          callout: callout,
          toolSummaries: summaries,
        ));
      });
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _isTyping = false;
        _messages.add(AiChatAssistantTurn(
          body: l10n.aiConnectionError,
          timeLabel: '',
        ));
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
                        AiChatMessageTile(item: _messages[i]),
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
                if (!_showQuickReplies && _messages.isEmpty && _initialSuggestedActions.isNotEmpty)
                  AiChatQuickReplies(
                    actions: _initialSuggestedActions,
                    onSelected: _handleQuickAction,
                  ),
              ],
            ),
          ),
          AiChatComposer(
            controller: _composer,
            enabled: !_isTyping,
            onSend: () => _sendMessage(_composer.text),
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
}
