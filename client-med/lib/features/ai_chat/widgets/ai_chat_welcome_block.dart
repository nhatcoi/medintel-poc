import 'package:flutter/material.dart';

import '../../../core/theme/vitalis_colors.dart';
import '../data/ai_chat_demo_data.dart';

class AiChatWelcomeBlock extends StatelessWidget {
  const AiChatWelcomeBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  VitalisColors.primary,
                  VitalisColors.primaryContainer,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: VitalisColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'How are you feeling, $kAiChatUserName?',
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: VitalisColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "I'm here to help with your medications and health questions.",
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(
              color: VitalisColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
