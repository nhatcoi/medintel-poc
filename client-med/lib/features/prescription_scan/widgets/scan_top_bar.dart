import 'package:flutter/material.dart';

import '../../../core/theme/vitalis_colors.dart';

class ScanTopBar extends StatelessWidget {
  const ScanTopBar({super.key, this.hasImage = false, this.onReset});

  final bool hasImage;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: VitalisColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.document_scanner_outlined,
              color: VitalisColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Quét đơn thuốc',
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: VitalisColors.onSurface,
            ),
          ),
          const Spacer(),
          if (hasImage)
            IconButton(
              onPressed: onReset,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Huỷ',
              color: VitalisColors.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}
