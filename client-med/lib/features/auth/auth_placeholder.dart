import 'package:flutter/material.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

/// Luồng đăng nhập / JWT — thay bằng màn hình thật + repository.
class AuthPlaceholder extends StatelessWidget {
  const AuthPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authTitle)),
      body: Center(child: Text(l10n.authBody)),
    );
  }
}
