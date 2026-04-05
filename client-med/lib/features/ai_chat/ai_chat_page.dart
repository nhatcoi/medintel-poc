import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/vitalis_colors.dart';
import '../../providers/local_medintel_provider.dart';
import '../../services/api_service.dart';
import 'data/ai_chat_models.dart';
import 'data/chat_repository.dart';
import 'widgets/ai_chat_composer.dart';
import 'widgets/ai_chat_message_tile.dart';
import 'widgets/ai_chat_quick_replies.dart';
import 'widgets/ai_chat_top_bar.dart';
import 'widgets/ai_chat_typing_indicator.dart';
import 'widgets/ai_chat_welcome_block.dart';

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

  @override
  void initState() {
    super.initState();
    _composer = TextEditingController();
    _scroll = ScrollController();
    _repo = ChatRepository(ApiService());
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
      final result = await _repo.sendMessage(trimmed);
      if (!mounted) return;

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
        ));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(const AiChatAssistantTurn(
          body: 'Xin lỗi, không thể kết nối. Vui lòng thử lại.',
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
    return ColoredBox(
      color: VitalisColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AiChatTopBar(),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                const AiChatWelcomeBlock(),
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
                    onSelected: _sendMessage,
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
}
