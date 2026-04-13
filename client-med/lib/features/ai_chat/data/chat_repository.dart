import 'package:dio/dio.dart';

import '../../../services/api_service.dart';
import '../../../core/constants/api_paths.dart';
import 'ai_chat_models.dart';

class ChatSendResult {
  const ChatSendResult({
    required this.reply,
    required this.suggestedActions,
    this.toolCalls = const [],
    this.sessionId,
  });

  final String reply;
  final List<SuggestedChatAction> suggestedActions;
  /// Lệnh agent — client thực thi & lưu database.
  final List<Map<String, dynamic>> toolCalls;
  /// Phiên chat trên server (gửi lại ở lượt sau để nối tiếp).
  final String? sessionId;
}

class ChatRepository {
  const ChatRepository(this._api);

  final ApiService _api;

  /// Gợi ý dòng chữ chạy khi mở chat — server gom thuốc/log/bộ nhớ + LLM (hoặc template).
  Future<List<String>> fetchWelcomeHints(String profileId) async {
    final id = profileId.trim();
    if (id.isEmpty) return const [];

    try {
      final resp = await _api.client.get<Map<String, dynamic>>(
        ApiPaths.chatWelcomeHints,
        queryParameters: {'profile_id': id},
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );
      final raw = resp.data?['hints'];
      if (raw is! List<dynamic>) return const [];
      return raw
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .take(12)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<ChatSendResult> sendMessage(
    String text, {
    String? profileId,
    String? sessionId,
    bool includeMedicationContext = false,
  }) async {
    final body = <String, dynamic>{'text': text};
    if (profileId != null && profileId.trim().isNotEmpty) {
      body['profile_id'] = profileId.trim();
    }
    if (sessionId != null && sessionId.trim().isNotEmpty) {
      body['session_id'] = sessionId.trim();
    }
    if (includeMedicationContext) {
      body['include_medication_context'] = true;
    }

    final resp = await _api.client.post<Map<String, dynamic>>(
      ApiPaths.chatMessage,
      data: body,
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
        final cat = e['category']?.toString();
        actions.add(
          SuggestedChatAction(
            label: label,
            prompt: prompt.isNotEmpty ? prompt : label,
            kind: SuggestedActionKind.fromServer(cat),
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

    final sid = data?['session_id'];
    final sessionOut = sid != null && '$sid'.trim().isNotEmpty ? '$sid'.trim() : null;

    return ChatSendResult(
      reply: reply,
      suggestedActions: actions,
      toolCalls: tools,
      sessionId: sessionOut,
    );
  }
}
