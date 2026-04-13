import 'package:flutter/material.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

class PrescriptionScanPlaceholder extends StatelessWidget {
  const PrescriptionScanPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.placeholderScanTitle)),
      body: Center(child: Text(l10n.placeholderScanBody)),
    );
  }
}
