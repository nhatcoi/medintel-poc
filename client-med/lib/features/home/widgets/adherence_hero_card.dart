import 'package:flutter/material.dart';

import '../../../core/theme/vitalis_colors.dart';

/// Card hero tuân thủ — vòng progress lớn + tóm tắt liều.
class AdherenceHeroCard extends StatelessWidget {
  const AdherenceHeroCard({
    super.key,
    required this.adherenceFraction,
    required this.dosesTaken,
    required this.dosesTotal,
  });

  final double adherenceFraction;
  final int dosesTaken;
  final int dosesTotal;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final effectiveFraction = dosesTotal <= 0 ? 0.0 : adherenceFraction;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C6FD1), Color(0xFF005FB8)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF005FB8).withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TODAY'S PROGRESS",
                style: text.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$dosesTaken/$dosesTotal',
                      style: text.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    TextSpan(
                      text: '  TAKEN TODAY',
                      style: text.titleSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _MiniProgressBar(fraction: effectiveFraction),
              const SizedBox(height: 10),
              Text(
                dosesTotal <= 0
                    ? 'Hãy thêm thuốc để bắt đầu theo dõi.'
                    : 'Great start, tiếp tục duy trì đều đặn để đạt mục tiêu hôm nay.',
                style: text.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniProgressBar extends StatelessWidget {
  const _MiniProgressBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: fraction.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: VitalisColors.surfaceContainerLow,
        valueColor: const AlwaysStoppedAnimation<Color>(VitalisColors.primary),
      ),
    );
  }
}
