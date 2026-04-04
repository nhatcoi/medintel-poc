/// Tin nhắn demo AI Chat (Stitch / aichat.html).
sealed class AiChatItem {
  const AiChatItem();
}

class AiChatAssistantTurn extends AiChatItem {
  const AiChatAssistantTurn({
    required this.body,
    required this.timeLabel,
    this.callout,
  });

  final String body;
  final String timeLabel;
  final String? callout;
}

class AiChatUserTurn extends AiChatItem {
  const AiChatUserTurn({
    required this.body,
    required this.timeLabel,
  });

  final String body;
  final String timeLabel;
}
