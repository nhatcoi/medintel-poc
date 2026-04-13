import 'package:flutter/material.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../../core/theme/vitalis_colors.dart';

class ScanEmptyState extends StatelessWidget {
  const ScanEmptyState({
    super.key,
    required this.onCamera,
    required this.onGallery,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: VitalisColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.document_scanner_outlined,
              size: 48,
              color: VitalisColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.scanEmptyTitle,
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: VitalisColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.scanEmptyBody,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: VitalisColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(l10n.scanCapturePrescription),
              style: FilledButton.styleFrom(
                backgroundColor: VitalisColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(l10n.scanFromGallery),
              style: OutlinedButton.styleFrom(
                foregroundColor: VitalisColors.primary,
                side: const BorderSide(color: VitalisColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
