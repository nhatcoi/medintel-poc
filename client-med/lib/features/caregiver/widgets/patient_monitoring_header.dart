import 'package:flutter/material.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../../core/theme/vitalis_colors.dart';

/// Nhãn MONITORING + tên bệnh nhân + nút gọi / nhắn.
class PatientMonitoringHeader extends StatelessWidget {
  const PatientMonitoringHeader({
    super.key,
    required this.patientName,
    this.onCall,
    this.onMessage,
  });

  final String patientName;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.careMonitoringLabel,
            style: text.labelMedium?.copyWith(
              letterSpacing: 1.2,
              color: VitalisColors.neutral,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  patientName,
                  style: text.headlineMedium?.copyWith(
                    color: VitalisColors.caregiverHeroBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _CircleAction(
                icon: Icons.phone_rounded,
                background: VitalisColors.primary,
                foreground: Colors.white,
                onTap: onCall,
              ),
              const SizedBox(width: 10),
              _CircleAction(
                icon: Icons.chat_bubble_outline_rounded,
                background: VitalisColors.chipDateBackground,
                foreground: VitalisColors.caregiverHeroBlue,
                onTap: onMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.background,
    required this.foreground,
    this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: foreground, size: 22),
        ),
      ),
    );
  }
}
