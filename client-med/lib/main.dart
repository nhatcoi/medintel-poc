import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_intel_client/core/constants/app_constants.dart';
import 'package:med_intel_client/core/theme/app_theme.dart';
import 'package:med_intel_client/features/caregiver/caregiver_dashboard_page.dart';
import 'package:med_intel_client/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(
    const ProviderScope(
      child: MedIntelApp(),
    ),
  );
}

class MedIntelApp extends StatelessWidget {
  const MedIntelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.light(),
      home: const CaregiverDashboardPage(),
    );
  }
}
