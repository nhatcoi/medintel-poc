/// Tin nhắn AI Chat (timeline do người dùng + server).
sealed class AiChatItem {
  const AiChatItem();
}

/// Một nút gợi ý do server/LLM sinh (label hiển thị, prompt gửi lên khi chọn).
class SuggestedChatAction {
  const SuggestedChatAction({
    required this.label,
    required this.prompt,
  });

  final String label;
  final String prompt;
}

class AiChatAssistantTurn extends AiChatItem {
  const AiChatAssistantTurn({
    required this.body,
    required this.timeLabel,
    this.callout,
    this.suggestedActions = const [],
  });

  final String body;
  final String timeLabel;
  final String? callout;
  final List<SuggestedChatAction> suggestedActions;
}

class AiChatUserTurn extends AiChatItem {
  const AiChatUserTurn({
    required this.body,
    required this.timeLabel,
  });

  final String body;
  final String timeLabel;
}
