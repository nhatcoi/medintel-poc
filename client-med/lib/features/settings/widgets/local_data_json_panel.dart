import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/data/auth_notifier.dart';
import '../../../providers/display_preferences_provider.dart';
import '../../../providers/local_medintel_provider.dart';
import '../../../providers/providers.dart';
import '../../../providers/shared_preferences_provider.dart';
import '../../../services/local_medintel_store.dart';

/// Hiển thị snapshot JSON dữ liệu cục bộ để debug; tự làm mới mỗi [refreshInterval].
class LocalDataJsonPanel extends ConsumerStatefulWidget {
  const LocalDataJsonPanel({
    super.key,
    this.refreshInterval = const Duration(seconds: 5),
  });

  final Duration refreshInterval;

  @override
  ConsumerState<LocalDataJsonPanel> createState() => _LocalDataJsonPanelState();
}

class _LocalDataJsonPanelState extends ConsumerState<LocalDataJsonPanel> {
  Timer? _timer;
  DateTime _refreshedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.refreshInterval, (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    ref.invalidate(localMedintelProvider);
    ref.invalidate(displayPreferencesProvider);
    setState(() => _refreshedAt = DateTime.now());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = ref.watch(localMedintelProvider);
    final auth = ref.watch(authProvider);
    final display = ref.watch(displayPreferencesProvider);
    final prefs = ref.watch(sharedPreferencesProvider);

    final snapshot = <String, dynamic>{
      'refreshed_at': _refreshedAt.toIso8601String(),
      'refresh_interval_seconds': widget.refreshInterval.inSeconds,
      'local_medintel_state': local.toJson(),
      'auth': _authSnapshot(auth),
      'display_preferences': {
        'font_id': display.fontId,
        'text_scale': display.textScale,
      },
      'shared_preferences_known_keys': _knownPrefsSnapshot(prefs),
    };

    final pretty = const JsonEncoder.withIndent('  ').convert(snapshot);
    final mono = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * 0.92,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Dữ liệu cục bộ (JSON)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: _tick,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Làm mới'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tự làm mới mỗi ${widget.refreshInterval.inSeconds}s (đọc lại state từ SharedPreferences).',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              pretty,
              style: mono,
            ),
          ),
        ),
      ],
    );
  }

  static Map<String, dynamic> _authSnapshot(AuthState s) {
    final u = s.user;
    return {
      'onboard_status': s.status.name,
      'user': u == null
          ? null
          : {
              'id': u.id,
              'full_name': u.fullName,
              'email': u.email,
              'role': u.role,
            },
      'token': _tokenMeta(s.token),
    };
  }

  static Object? _tokenMeta(String? t) {
    if (t == null || t.isEmpty) return null;
    final len = t.length;
    final suffix = len > 6 ? t.substring(len - 6) : null;
    return {'length_chars': len, 'suffix': suffix};
  }

  static Map<String, Object?> _knownPrefsSnapshot(SharedPreferences? p) {
    if (p == null) {
      return {'error': 'SharedPreferences not available'};
    }
    final rawAgent = p.getString(kMedintelLocalAgentPrefsKey);
    return {
      'setup_done': p.getBool('setup_done'),
      'auth_user_id': p.getString('auth_user_id'),
      'auth_user_name': p.getString('auth_user_name'),
      'auth_token': _tokenMeta(p.getString('auth_token')),
      'display_font_id': p.getString('display_font_id'),
      'display_text_scale': p.getDouble('display_text_scale'),
      kMedintelLocalAgentPrefsKey: rawAgent == null
          ? null
          : {
              'json_char_length': rawAgent.length,
              'preview_head': rawAgent.length > 120 ? '${rawAgent.substring(0, 120)}…' : rawAgent,
            },
    };
  }
}
