import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_intel_client/app/router.dart';

void main() {
  testWidgets('Router shows Caregiver view on /care', (WidgetTester tester) async {
    final router = createMedIntelRouter();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('MedIntel'), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);
  });

  testWidgets('Bottom nav switches branch to Home', (WidgetTester tester) async {
    final router = createMedIntelRouter();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('HOME'));
    await tester.pumpAndSettle();
    expect(find.text('Tìm thuốc, bác sĩ, chức năng…'), findsOneWidget);
  });
}
