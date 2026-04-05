import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/auth_notifier.dart';
import '../features/auth/welcome_page.dart';
import '../features/auth/patient_setup_page.dart';
import '../features/caregiver/caregiver_dashboard_page.dart';
import '../features/settings/settings_page.dart';
import '../features/shell/branch_pages.dart';
import '../providers/providers.dart';
import 'shell/app_shell.dart';

GoRouter createMedIntelRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      final isOnboarding = loc == '/welcome' || loc == '/setup';

      if (auth.status == OnboardStatus.unknown) return null;
      if (auth.status == OnboardStatus.firstTime && !isOnboarding) return '/welcome';
      if (auth.status == OnboardStatus.completed && isOnboarding) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/setup',
        name: 'setup',
        builder: (context, state) => const PatientSetupPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              pageBuilder: (context, state) => NoTransitionPage<void>(
                key: state.pageKey,
                child: const HomeBranchPage(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/scan',
              name: 'scan',
              pageBuilder: (context, state) => NoTransitionPage<void>(
                key: state.pageKey,
                child: const ScanBranchPage(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/ai',
              name: 'ai',
              pageBuilder: (context, state) => NoTransitionPage<void>(
                key: state.pageKey,
                child: const AiBranchPage(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/history',
              name: 'history',
              pageBuilder: (context, state) => NoTransitionPage<void>(
                key: state.pageKey,
                child: const HistoryBranchPage(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/care',
              name: 'care',
              pageBuilder: (context, state) => NoTransitionPage<void>(
                key: state.pageKey,
                child: const CaregiverDashboardPage(),
              ),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}
