/// Tin nhắn AI Chat (timeline do người dùng + server).
sealed class AiChatItem {
  const AiChatItem();
}

/// Nhóm gợi ý do server phân loại (khớp `category` trong JSON).
enum SuggestedActionKind {
  app,
  knowledge,
  other;

  static SuggestedActionKind fromServer(String? raw) {
    switch ((raw ?? 'other').toLowerCase().trim()) {
      case 'app':
        return SuggestedActionKind.app;
      case 'knowledge':
        return SuggestedActionKind.knowledge;
      default:
        return SuggestedActionKind.other;
    }
  }
}

/// Một nút gợi ý do server/LLM sinh (label hiển thị, prompt gửi lên khi chọn).
class SuggestedChatAction {
  const SuggestedChatAction({
    required this.label,
    required this.prompt,
    this.kind = SuggestedActionKind.other,
  });

  final String label;
  final String prompt;
  final SuggestedActionKind kind;
}

class ScannedMedicationPreview {
  const ScannedMedicationPreview({
    required this.name,
    this.dosage,
    this.frequency,
    this.instructions,
    this.times = const [],
  });

  final String name;
  final String? dosage;
  final String? frequency;
  final String? instructions;
  final List<String> times;
}

class ScanPrescriptionPreviewResult {
  const ScanPrescriptionPreviewResult({
    required this.diseaseName,
    required this.medications,
  });

  final String diseaseName;
  final List<ScannedMedicationPreview> medications;

  bool get looksLikePrescription => medications.isNotEmpty;
}

class AiChatAssistantTurn extends AiChatItem {
  const AiChatAssistantTurn({
    required this.body,
    required this.timeLabel,
    this.callout,
    this.toolSummaries = const [],
    this.suggestedActions = const [],
  });

  final String body;
  final String timeLabel;
  final String? callout;
  final List<String> toolSummaries;
  final List<SuggestedChatAction> suggestedActions;
}

class AiChatUserTurn extends AiChatItem {
  const AiChatUserTurn({required this.body, required this.timeLabel});

  final String body;
  final String timeLabel;
}
