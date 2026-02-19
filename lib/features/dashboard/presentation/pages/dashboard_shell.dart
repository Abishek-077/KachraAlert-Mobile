import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/k_widgets.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _go(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MotionScaffold(
      body: navigationShell,
      bottomNavigationBar: KBottomNavDock(
        currentIndex: navigationShell.currentIndex,
        onIndexChanged: _go,
        onFabTap: () => context.push('/reports/create'),
      ),
    );
  }
}
