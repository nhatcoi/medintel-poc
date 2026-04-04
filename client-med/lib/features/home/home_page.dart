import 'package:flutter/material.dart';
import 'package:med_intel_client/core/theme/vitalis_colors.dart';
import 'package:med_intel_client/core/widgets/vitalis_widgets.dart';
import 'package:med_intel_client/features/adherence/adherence_placeholder.dart';
import 'package:med_intel_client/features/ai_chat/ai_chat_placeholder.dart';
import 'package:med_intel_client/features/auth/auth_placeholder.dart';
import 'package:med_intel_client/features/medication/medication_placeholder.dart';
import 'package:med_intel_client/features/prescription_scan/prescription_scan_placeholder.dart';
import 'package:med_intel_client/features/reminder/reminder_placeholder.dart';

/// Hub theo design system — tóm tắt + tìm kiếm + danh sách feature (không divider cứng).
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('MedIntel')),
      body: _navIndex == 0 ? _buildHome(context, text) : _buildProfileStub(context, text),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }

  Widget _buildHome(BuildContext context, TextTheme text) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          'Xin chào',
          style: text.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Hôm nay bạn thế nào?',
          style: text.bodyLarge?.copyWith(color: VitalisColors.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
        VitalisSoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tóm tắt trong ngày', style: text.titleLarge),
              const SizedBox(height: 12),
              Text(
                'Tuân thủ điều trị và lịch thuốc sẽ hiển thị tại đây.',
                style: text.bodyLarge,
              ),
              const SizedBox(height: 24),
              Center(
                child: VitalisPrimaryGradientButton(
                  label: 'Đánh dấu đã uống thuốc',
                  icon: Icons.medication_liquid_rounded,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const VitalisSearchField(hintText: 'Tìm thuốc, bác sĩ…'),
        const SizedBox(height: 32),
        Text('Chức năng', style: text.titleMedium),
        const SizedBox(height: 16),
        _featureTile(context, 'auth', 'Đăng nhập / JWT', Icons.lock_outline_rounded, const AuthPlaceholder()),
        const SizedBox(height: 32),
        _featureTile(context, 'medication', 'Thuốc của tôi', Icons.medication_outlined, const MedicationPlaceholder()),
        const SizedBox(height: 32),
        _featureTile(
            context, 'prescription_scan', 'Quét đơn thuốc', Icons.document_scanner_outlined, const PrescriptionScanPlaceholder()),
        const SizedBox(height: 32),
        _featureTile(context, 'reminder', 'Nhắc thuốc', Icons.notifications_active_outlined, const ReminderPlaceholder()),
        const SizedBox(height: 32),
        _featureTile(context, 'adherence', 'Tuân thủ', Icons.check_circle_outline_rounded, const AdherencePlaceholder()),
        const SizedBox(height: 32),
        _featureTile(context, 'ai_chat', 'AI hỗ trợ', Icons.chat_bubble_outline_rounded, const AiChatPlaceholder()),
      ],
    );
  }

  Widget _buildProfileStub(BuildContext context, TextTheme text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Hồ sơ & cài đặt (sắp tới)',
          style: text.bodyLarge?.copyWith(color: VitalisColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _featureTile(
    BuildContext context,
    String key,
    String title,
    IconData icon,
    Widget page,
  ) {
    final theme = Theme.of(context);
    return Material(
      color: VitalisColors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => page),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Icon(icon, size: 28, color: VitalisColors.secondary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
              Icon(Icons.chevron_right_rounded, color: VitalisColors.neutral.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
