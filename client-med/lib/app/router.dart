import 'package:go_router/go_router.dart';

import 'shell/app_shell.dart';
import '../features/caregiver/caregiver_dashboard_page.dart';
import '../features/settings/settings_page.dart';
import '../features/shell/branch_pages.dart';

/// Tạo router mới (test dùng để tránh state leak giữa các `testWidgets`).
GoRouter createMedIntelRouter({String initialLocation = '/care'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: const HomeBranchPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scan',
                name: 'scan',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: const ScanBranchPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ai',
                name: 'ai',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: const AiBranchPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                name: 'history',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: const HistoryBranchPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/care',
                name: 'care',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: const CaregiverDashboardPage(),
                ),
              ),
            ],
          ),
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

/// Router singleton cho app.
final GoRouter appRouter = createMedIntelRouter();
