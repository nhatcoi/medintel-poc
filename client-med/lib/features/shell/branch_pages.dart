import 'package:flutter/material.dart';

import '../../core/theme/vitalis_colors.dart';
import '../ai_chat/ai_chat_page.dart';
import '../home/home_page.dart';
import '../prescription_scan/prescription_scan_page.dart';

/// Các màn placeholder cho nhánh shell (sau thay bằng feature thật).
class HomeBranchPage extends StatelessWidget {
  const HomeBranchPage({super.key});

  @override
  Widget build(BuildContext context) => const HomePage();
}

class ScanBranchPage extends StatelessWidget {
  const ScanBranchPage({super.key});

  @override
  Widget build(BuildContext context) => const PrescriptionScanPage();
}

class AiBranchPage extends StatelessWidget {
  const AiBranchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AiChatPage();
  }
}

class HistoryBranchPage extends StatelessWidget {
  const HistoryBranchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _BranchBody(
      title: 'History',
      subtitle: 'Nhật ký uống thuốc & cảnh báo',
      icon: Icons.history_rounded,
    );
  }
}

class _BranchBody extends StatelessWidget {
  const _BranchBody({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 56, color: VitalisColors.primary.withValues(alpha: 0.85)),
                const SizedBox(height: 20),
                Text(title, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(color: VitalisColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
