import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
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
    final pct = dosesTotal <= 0 ? 0 : (adherenceFraction * 100).round();
    final remaining = dosesTotal <= 0 ? 0 : dosesTotal - dosesTaken;
    final effectiveFraction = dosesTotal <= 0 ? 0.0 : adherenceFraction;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: VitalisColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: VitalisColors.ambientFloating,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AdherenceRing(
                fraction: effectiveFraction,
                percentLabel: dosesTotal <= 0 ? '—' : '$pct%',
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TUÂN THỦ HÔM NAY',
                      style: text.labelMedium?.copyWith(
                        color: VitalisColors.neutral,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _StatRow(
                      icon: Icons.check_circle_rounded,
                      color: VitalisColors.statusSuccess,
                      label: dosesTotal <= 0
                          ? 'Chưa có thuốc trong lịch hôm nay'
                          : '$dosesTaken liều đã uống',
                      style: text.bodyMedium?.copyWith(
                        color: VitalisColors.statusSuccess,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatRow(
                      icon: Icons.access_time_rounded,
                      color: VitalisColors.neutral,
                      label: dosesTotal <= 0
                          ? 'Thêm thuốc để theo dõi tuân thủ'
                          : '$remaining liều còn lại',
                      style: text.bodyMedium?.copyWith(
                        color: VitalisColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _MiniProgressBar(fraction: effectiveFraction),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdherenceRing extends StatelessWidget {
  const _AdherenceRing({
    required this.fraction,
    required this.percentLabel,
  });

  final double fraction;
  final String percentLabel;

  static const double _size = 128;
  static const double _stroke = 13;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: _size,
            height: _size,
            child: CircularProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              strokeWidth: _stroke,
              strokeCap: StrokeCap.round,
              backgroundColor: VitalisColors.surfaceContainerLow,
              valueColor: const AlwaysStoppedAnimation<Color>(VitalisColors.primary),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                percentLabel,
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: VitalisColors.onSurface,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'hoàn thành',
                style: text.labelSmall?.copyWith(
                  color: VitalisColors.neutral,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.style,
  });

  final IconData icon;
  final Color color;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
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
