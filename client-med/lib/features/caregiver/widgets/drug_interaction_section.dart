import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vitalis_colors.dart';
import '../data/drug_interaction_models.dart';

class DrugInteractionSection extends StatelessWidget {
  const DrugInteractionSection({
    super.key,
    required this.loading,
    required this.pairs,
    required this.error,
    required this.onRefresh,
    required this.onAskAi,
  });

  final bool loading;
  final List<DrugInteractionPair> pairs;
  final String? error;
  final VoidCallback onRefresh;
  final void Function(DrugInteractionPair pair) onAskAi;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final risky = pairs
        .where((p) =>
            p.severity == InteractionSeverity.high ||
            p.severity == InteractionSeverity.medium)
        .toList();
    final unknown = pairs
        .where((p) => p.severity == InteractionSeverity.unknown)
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.medication_liquid_rounded,
                  color: VitalisColors.caregiverHeroBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cảnh báo tương tác thuốc',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: VitalisColors.caregiverHeroBlue,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Kiểm tra lại',
                onPressed: loading ? null : onRefresh,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
              ),
            ],
          ),
          Text(
            'Đối chiếu ngữ nghĩa (pgvector) giữa các thuốc trong tủ.'
            '${unknown > 0 ? ' $unknown cặp thiếu dữ liệu nội bộ.' : ''}',
            style: text.bodySmall?.copyWith(
              color: VitalisColors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          if (error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VitalisColors.statusErrorSoft,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Text(
                'Không tải được dữ liệu tương tác: $error',
                style: text.bodySmall?.copyWith(
                  color: VitalisColors.statusError,
                ),
              ),
            )
          else if (pairs.isEmpty && !loading)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: VitalisColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: VitalisColors.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cần ít nhất 2 thuốc trong tủ để đối chiếu tương tác.',
                      style: text.bodyMedium?.copyWith(
                        color: VitalisColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (risky.isEmpty && !loading)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: VitalisColors.statusSuccessSoft,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      color: VitalisColors.statusSuccess),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Không phát hiện tương tác rõ ràng giữa các thuốc. '
                      '${unknown > 0 ? 'Tuy nhiên $unknown cặp thiếu dữ liệu — có thể hỏi AI/Tavily để kiểm tra ngoài.' : ''}',
                      style: text.bodyMedium?.copyWith(
                        color: VitalisColors.statusSuccess,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            for (final p in risky) ...[
              _InteractionCard(pair: p, onAskAi: () => onAskAi(p)),
              const SizedBox(height: 8),
            ],
          if (unknown > 0 && risky.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '$unknown cặp thuốc chưa có trong kho tri thức. Mở AI để tìm thêm (Tavily).',
                style: text.bodySmall?.copyWith(
                  color: VitalisColors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InteractionCard extends StatelessWidget {
  const _InteractionCard({required this.pair, required this.onAskAi});

  final DrugInteractionPair pair;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = _paletteFor(pair.severity);
    final topEvidence =
        pair.evidence.isNotEmpty ? pair.evidence.first : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: palette.fg.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: palette.fg.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(palette.icon, color: palette.fg, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pair.drugA,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: VitalisColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.compare_arrows_rounded,
                            size: 16, color: palette.fg),
                        Flexible(
                          child: Text(
                            pair.drugB,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: VitalisColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${palette.label} · nguồn: ${pair.source.toUpperCase()}',
                      style: text.bodySmall?.copyWith(
                        color: palette.fg,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            pair.summary,
            style: text.bodySmall?.copyWith(
              color: VitalisColors.onSurface,
              height: 1.4,
            ),
          ),
          if (topEvidence != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: palette.fg.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📚 ${topEvidence.drugName} · ${topEvidence.section} '
                    '(sim ${topEvidence.similarity.toStringAsFixed(2)})',
                    style: text.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.fg,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    topEvidence.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: VitalisColors.onSurfaceVariant,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: onAskAi,
                icon: const Icon(Icons.smart_toy_rounded, size: 16),
                label: const Text('Hỏi AI / Tavily'),
                style: TextButton.styleFrom(
                  foregroundColor: palette.fg,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _InteractionPalette _paletteFor(InteractionSeverity s) {
    switch (s) {
      case InteractionSeverity.high:
        return const _InteractionPalette(
          bg: Color(0xFFFFEBEE),
          fg: VitalisColors.statusError,
          icon: Icons.dangerous_rounded,
          label: 'NGUY CƠ CAO',
        );
      case InteractionSeverity.medium:
        return const _InteractionPalette(
          bg: Color(0xFFFFF3E0),
          fg: Color(0xFFBF5A00),
          icon: Icons.warning_amber_rounded,
          label: 'THẬN TRỌNG',
        );
      case InteractionSeverity.low:
        return const _InteractionPalette(
          bg: Color(0xFFE3F2FD),
          fg: VitalisColors.chipDateForeground,
          icon: Icons.info_rounded,
          label: 'NHẸ',
        );
      case InteractionSeverity.unknown:
        return const _InteractionPalette(
          bg: Color(0xFFF5F5F5),
          fg: VitalisColors.onSurfaceVariant,
          icon: Icons.help_outline_rounded,
          label: 'CHƯA RÕ',
        );
    }
  }
}

class _InteractionPalette {
  const _InteractionPalette({
    required this.bg,
    required this.fg,
    required this.icon,
    required this.label,
  });

  final Color bg;
  final Color fg;
  final IconData icon;
  final String label;
}
