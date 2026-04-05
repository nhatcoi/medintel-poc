import 'package:dio/dio.dart';

import '../../../services/api_service.dart';
import 'ai_chat_models.dart';

class ChatSendResult {
  const ChatSendResult({
    required this.reply,
    required this.suggestedActions,
    this.toolCalls = const [],
  });

  final String reply;
  final List<SuggestedChatAction> suggestedActions;
  /// Lệnh agent — client thực thi & lưu cục bộ.
  final List<Map<String, dynamic>> toolCalls;
}

class ChatRepository {
  const ChatRepository(this._api);

  final ApiService _api;

  Future<ChatSendResult> sendMessage(String text) async {
    final resp = await _api.client.post<Map<String, dynamic>>(
      '/api/v1/chat/message',
      data: {'text': text},
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );
    final data = resp.data;
    final reply = data?['reply'];
    if (reply is! String || reply.isEmpty) {
      throw const FormatException('Empty reply from server');
    }

    final actions = <SuggestedChatAction>[];
    final raw = data?['suggested_actions'];
    if (raw is List<dynamic>) {
      for (final e in raw) {
        if (e is! Map<String, dynamic>) continue;
        final label = e['label']?.toString().trim() ?? '';
        if (label.isEmpty) continue;
        final prompt = e['prompt']?.toString().trim() ?? '';
        actions.add(
          SuggestedChatAction(
            label: label,
            prompt: prompt.isNotEmpty ? prompt : label,
          ),
        );
      }
    }

    final tools = <Map<String, dynamic>>[];
    final rawTools = data?['tool_calls'];
    if (rawTools is List<dynamic>) {
      for (final e in rawTools) {
        if (e is! Map<String, dynamic>) continue;
        final tool = e['tool']?.toString().trim() ?? '';
        if (tool.isEmpty) continue;
        final args = e['args'];
        final argMap = <String, dynamic>{};
        if (args is Map) {
          args.forEach((k, v) => argMap[k.toString()] = v);
        }
        tools.add({'tool': tool, 'args': argMap});
      }
    }

    return ChatSendResult(
      reply: reply,
      suggestedActions: actions,
      toolCalls: tools,
    );
  }
}
