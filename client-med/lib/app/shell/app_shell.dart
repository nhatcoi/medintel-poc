import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'sliding_circle_nav_bar.dart';

/// Shell chung: SafeArea trên + [StatefulNavigationShell] + bottom bar bo góc.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onNavTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: navigationShell,
      ),
      bottomNavigationBar: SlidingCircleNavBar(
        currentIndex: navigationShell.currentIndex,
        onDestinationSelected: _onNavTap,
      ),
    );
  }
}
