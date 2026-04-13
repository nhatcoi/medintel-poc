import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../../core/theme/vitalis_colors.dart';
import '../../../providers/providers.dart';
import 'ai_chat_welcome_typewriter.dart';

class AiChatWelcomeBlock extends ConsumerWidget {
  const AiChatWelcomeBlock({
    super.key,
    required this.rotatingPhrases,
    this.showTypewriter = true,
  });

  /// Ưu tiên từ API `/chat/welcome-hints`; khi lỗi dùng fallback l10n (cha truyền vào).
  final List<String> rotatingPhrases;

  /// Khi đã có hội thoại, ẩn dòng chữ chạy để tập trung vào tin nhắn.
  final bool showTypewriter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final auth = ref.watch(authProvider);
    final name = auth.user?.fullName?.trim().isNotEmpty == true
        ? auth.user!.fullName!.trim()
        : l10n.genericYou;

    final phrases = rotatingPhrases.where((e) => e.trim().isNotEmpty).toList();

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
            l10n.aiWelcomeGreeting(name),
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: VitalisColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.aiWelcomeBody,
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(
              color: VitalisColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          if (showTypewriter && phrases.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              l10n.aiChatRotatingCaption,
              style: text.labelSmall?.copyWith(
                color: VitalisColors.neutral,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            AiChatWelcomeTypewriter(phrases: phrases),
          ],
        ],
      ),
    );
  }
}
