import 'package:flutter/material.dart';

class AiChatPlaceholder extends StatelessWidget {
  const AiChatPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Chat')),
      body: const Center(child: Text('ai_chat — RAG + LLM')),
    );
  }
}
