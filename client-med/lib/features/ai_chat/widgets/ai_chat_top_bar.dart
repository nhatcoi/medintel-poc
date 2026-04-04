import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/vitalis_colors.dart';

/// Header giống aichat.html: avatar, MedIntel (xanh đậm), cài đặt.
class AiChatTopBar extends StatelessWidget {
  const AiChatTopBar({super.key});

  static const String _avatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuD9kwn9aSDiwEg7BJxeZNzBld6q8wPNhDS7xX5nqQbV5XQG6BXtyKLGw-wj0tZ7IttB7eb5M-UKH1hGAO83nUjXJnVmp6B9OzBKs1T1-dnU1qiYlk99ypeGgEbvK88mJX__kGINkNB26oG_kDKDAOPFp2YlGJUJb0LMsfr4UW0T3g-oDsA8-dIOHUh66ULVXGOXY4x_EYd5a3anCaMawKif5f_uVdg4WXFBHP1D5lm3CBnASrdoerxFdWbs6Kx8PNx8uzpBXKcEaf8';

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: const Color(0xFF1E3A5F),
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
          fontSize: 22,
        );

    return Material(
      color: VitalisColors.surface.withValues(alpha: 0.82),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: VitalisColors.primaryContainer, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                _avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: VitalisColors.primaryContainer.withValues(alpha: 0.35),
                  child: const Icon(Icons.person_rounded, color: VitalisColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('MedIntel', style: titleStyle),
            ),
            IconButton(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings_outlined),
              color: VitalisColors.onSurfaceVariant,
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
            ),
          ],
        ),
      ),
    );
  }
}
