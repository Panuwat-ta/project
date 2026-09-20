import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_translations.dart';

/// Single Material 3 primary navigation authority for the main app areas.
class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({super.key, required this.child});

  final Widget child;

  static const double expandedBreakpoint = 840;

  static int indexForPath(String path) {
    if (path.startsWith('/main/history')) return 1;
    if (path.startsWith('/main/report')) return 2;
    if (path.startsWith('/main/settings')) return 3;
    return 0;
  }

  void _goToIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/main/home');
        break;
      case 1:
        context.go('/main/history');
        break;
      case 2:
        context.go('/main/report');
        break;
      case 3:
        context.go('/main/settings');
        break;
    }
  }

  List<NavigationDestination> _barDestinations(BuildContext context) => [
    NavigationDestination(
      icon: const Icon(Icons.home_outlined),
      selectedIcon: const Icon(Icons.home),
      label: 'home'.tr(context),
    ),
    NavigationDestination(
      icon: const Icon(Icons.history_outlined),
      selectedIcon: const Icon(Icons.history),
      label: 'history'.tr(context),
    ),
    NavigationDestination(
      icon: const Icon(Icons.flag_outlined),
      selectedIcon: const Icon(Icons.flag),
      label: 'report'.tr(context),
    ),
    NavigationDestination(
      icon: const Icon(Icons.settings_outlined),
      selectedIcon: const Icon(Icons.settings),
      label: 'settings'.tr(context),
    ),
  ];

  List<NavigationRailDestination> _railDestinations(BuildContext context) => [
    NavigationRailDestination(
      icon: const Icon(Icons.home_outlined),
      selectedIcon: const Icon(Icons.home),
      label: Text('home'.tr(context)),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.history_outlined),
      selectedIcon: const Icon(Icons.history),
      label: Text('history'.tr(context)),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.flag_outlined),
      selectedIcon: const Icon(Icons.flag),
      label: Text('report'.tr(context)),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.settings_outlined),
      selectedIcon: const Icon(Icons.settings),
      label: Text('settings'.tr(context)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = indexForPath(path);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= expandedBreakpoint) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => _goToIndex(context, index),
                  labelType: NavigationRailLabelType.all,
                  destinations: _railDestinations(context),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }

        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _goToIndex(context, index),
            destinations: _barDestinations(context),
          ),
        );
      },
    );
  }
}
