import 'package:flutter/material.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vitalis_colors.dart';

/// Lưới 2 cột: adherence (trái) + weekly (phải).
class MonitoringCardsBlock extends StatelessWidget {
  const MonitoringCardsBlock({
    super.key,
    required this.adherenceFraction,
    required this.dosesTaken,
    required this.dosesTotal,
    required this.weeklyScoreFraction,
    required this.weeklyCaption,
    required this.vitalsHeadline,
    required this.vitalsSub,
  });

  final double adherenceFraction;
  final int dosesTaken;
  final int dosesTotal;
  final double weeklyScoreFraction;
  final String weeklyCaption;
  final String vitalsHeadline;
  final String vitalsSub;

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    const cardHeight = 240.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              height: cardHeight,
              child: _AdherenceCard(
                fraction: adherenceFraction,
                dosesTaken: dosesTaken,
                dosesTotal: dosesTotal,
              ),
            ),
          ),
          const SizedBox(width: gap),
          Expanded(
            child: SizedBox(
              height: cardHeight,
              child: _WeeklyScoreCard(
                fraction: weeklyScoreFraction,
                caption: weeklyCaption,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({
    required this.child,
    required this.radius,
    this.color,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final double radius;
  final Color? color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? VitalisColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: VitalisColors.ambientFloating,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _AdherenceCard extends StatelessWidget {
  const _AdherenceCard({
    required this.fraction,
    required this.dosesTaken,
    required this.dosesTotal,
  });

  final double fraction;
  final int dosesTaken;
  final int dosesTotal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final pct = (fraction * 100).round();

    return _SoftPanel(
      radius: AppTheme.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.careTodayAdherence,
            style: text.titleSmall?.copyWith(
              color: VitalisColors.neutral,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Center(
              child: _DonutProgress(
                fraction: fraction,
                percentLabel: '$pct%',
                size: 112,
                stroke: 10,
              ),
            ),
          ),
          Text(
            dosesTotal <= 0
                ? l10n.careDosesNoSchedule
                : l10n.careDosesLogged(dosesTaken, dosesTotal),
            textAlign: TextAlign.center,
            style: text.labelMedium?.copyWith(
              color: VitalisColors.statusSuccess,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutProgress extends StatelessWidget {
  const _DonutProgress({
    required this.fraction,
    required this.percentLabel,
    required this.size,
    required this.stroke,
  });

  final double fraction;
  final String percentLabel;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              strokeWidth: stroke,
              strokeCap: StrokeCap.round,
              backgroundColor: VitalisColors.surfaceContainerLow,
              valueColor: const AlwaysStoppedAnimation<Color>(VitalisColors.primary),
            ),
          ),
          Text(
            percentLabel,
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: VitalisColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyScoreCard extends StatelessWidget {
  const _WeeklyScoreCard({
    required this.fraction,
    required this.caption,
  });

  final double fraction;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final pct = (fraction * 100).round();

    return _SoftPanel(
      color: VitalisColors.caregiverHeroBlue,
      radius: AppTheme.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.careWeeklyScore,
            style: text.titleSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '$pct%',
            textAlign: TextAlign.center,
            style: text.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: text.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

