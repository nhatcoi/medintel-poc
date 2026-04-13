import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_intel_client/app/router.dart';
import 'package:med_intel_client/core/theme/app_theme.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';
import 'package:med_intel_client/providers/display_preferences_provider.dart';
import 'package:med_intel_client/providers/locale_preferences_provider.dart';
import 'package:med_intel_client/providers/shared_preferences_provider.dart';
import 'package:med_intel_client/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences?> _loadSharedPreferences() async {
  try {
    return await SharedPreferences.getInstance();
  } on PlatformException catch (e, st) {
    debugPrint(
      'SharedPreferences: ${e.code} — ${e.message}\n'
      'Thường do hot restart iOS sau khi thêm plugin. Dừng app và chạy lại: flutter run',
    );
    debugPrintStack(stackTrace: st);
    return null;
  } catch (e, st) {
    debugPrint('SharedPreferences: $e');
    debugPrintStack(stackTrace: st);
    return null;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  final sharedPrefs = await _loadSharedPreferences();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const MedIntelApp(),
    ),
  );
}

class MedIntelApp extends ConsumerStatefulWidget {
  const MedIntelApp({super.key});

  @override
  ConsumerState<MedIntelApp> createState() => _MedIntelAppState();
}

class _MedIntelAppState extends ConsumerState<MedIntelApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createMedIntelRouter(ref);
  }

  @override
  Widget build(BuildContext context) {
    final display = ref.watch(displayPreferencesProvider);
    final appLang = ref.watch(appLocaleProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light(fontId: display.fontId),
      routerConfig: _router,
      locale: Locale(appLang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(display.textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
