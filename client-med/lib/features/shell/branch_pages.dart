import 'package:flutter/material.dart';

import '../ai_chat/ai_chat_page.dart';
import '../history/history_page.dart';
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
    return const HistoryPage();
  }
}
