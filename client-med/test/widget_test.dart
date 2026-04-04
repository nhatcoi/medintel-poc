import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_intel_client/features/caregiver/caregiver_dashboard_page.dart';

void main() {
  testWidgets('Caregiver dashboard shows patient and monitoring', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: CaregiverDashboardPage()),
      ),
    );
    expect(find.text('MedIntel'), findsOneWidget);
    expect(find.text('MONITORING'), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text("Today's Adherence"), findsOneWidget);
    expect(find.text('Medications'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Recent Alerts'), findsOneWidget);
  });
}
