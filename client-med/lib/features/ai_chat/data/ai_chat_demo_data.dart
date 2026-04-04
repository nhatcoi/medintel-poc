import 'ai_chat_models.dart';

const String kAiChatUserName = 'Sarah';

const List<AiChatItem> kAiChatDemoTimeline = [
  AiChatAssistantTurn(
    body:
        "Good morning! I noticed it's time for your 9:00 AM Metformin dose. Have you taken it yet?",
    timeLabel: '09:05 AM',
  ),
  AiChatUserTurn(
    body: "Yes, I just took it with breakfast. But I'm feeling a bit dizzy today.",
    timeLabel: '09:12 AM',
  ),
  AiChatAssistantTurn(
    body:
        "I've noted that. Dizziness can sometimes happen if your blood sugar is a little low after the dose.",
    timeLabel: '',
    callout:
        'Try to sit down and rest for 15 minutes. Would you like me to check if this is a known side effect of your current dosage?',
  ),
];

const List<String> kAiChatQuickReplies = [
  'Check side effects?',
  'Log symptoms',
  'Next dose?',
];
