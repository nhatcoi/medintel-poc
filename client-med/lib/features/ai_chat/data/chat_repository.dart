import 'package:dio/dio.dart';

import '../../../services/api_service.dart';

class ChatRepository {
  const ChatRepository(this._api);

  final ApiService _api;

  Future<String> sendMessage(String text) async {
    final resp = await _api.client.post<Map<String, dynamic>>(
      '/api/v1/chat/message',
      data: {'text': text},
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );
    final reply = resp.data?['reply'];
    if (reply is String && reply.isNotEmpty) return reply;
    throw const FormatException('Empty reply from server');
  }
}
