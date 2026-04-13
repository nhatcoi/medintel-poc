import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:med_intel_client/app/router.dart';
import 'package:med_intel_client/features/home/home_page.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';
import 'package:med_intel_client/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Giữ một [GoRouter] cho cả test (tránh tạo lại mỗi lần build như [Consumer] thuần).
class _TestAppShell extends ConsumerStatefulWidget {
  const _TestAppShell();

  @override
  ConsumerState<_TestAppShell> createState() => _TestAppShellState();
}

class _TestAppShellState extends ConsumerState<_TestAppShell> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    _router ??= createMedIntelRouter(ref);
    return MaterialApp.router(
      routerConfig: _router!,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'setup_done': true,
      'auth_token': 'test_token',
      'auth_user_id': 'u1',
      'auth_user_name': 'Người thử nghiệm',
    });
  });

  testWidgets('Shell: Care tab shows user name from auth', (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const _TestAppShell(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('CHĂM SÓC'));
    await tester.pumpAndSettle();
    expect(find.text('MedIntel'), findsOneWidget);
    expect(find.text('Người thử nghiệm'), findsWidgets);
    expect(find.text('THEO DÕI'), findsOneWidget);
  });

  testWidgets('Bottom nav switches branch to Home', (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const _TestAppShell(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('TRANG CHỦ'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });
}
