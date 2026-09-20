import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:scam_image_mobile/core/widgets/main_navigation_shell.dart';

void main() {
  test('path mapping has a single router-derived selected destination', () {
    expect(MainNavigationShell.indexForPath('/main/home'), 0);
    expect(MainNavigationShell.indexForPath('/main/history'), 1);
    expect(MainNavigationShell.indexForPath('/main/report'), 2);
    expect(MainNavigationShell.indexForPath('/main/settings'), 3);
    expect(MainNavigationShell.indexForPath('/main/settings/profile'), 3);
  });

  testWidgets('main shell uses Material 3 NavigationBar and can switch tabs', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/main/home',
      routes: [
        ShellRoute(
          builder: (_, _, child) => MainNavigationShell(child: child),
          routes: [
            GoRoute(
              path: '/main/home',
              builder: (_, _) => const Text('Home page'),
            ),
            GoRoute(
              path: '/main/history',
              builder: (_, _) => const Text('History page'),
            ),
            GoRoute(
              path: '/main/report',
              builder: (_, _) => const Text('Report page'),
            ),
            GoRoute(
              path: '/main/settings',
              builder: (_, _) => const Text('Settings page'),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    await tester.tap(find.text('ประวัติ'));
    await tester.pumpAndSettle();
    expect(find.text('History page'), findsOneWidget);
  });

  testWidgets('expanded width uses NavigationRail instead of bottom bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(840, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/main/home',
      routes: [
        ShellRoute(
          builder: (_, _, child) => MainNavigationShell(child: child),
          routes: [
            GoRoute(
              path: '/main/home',
              builder: (_, _) => const Text('Home page'),
            ),
            GoRoute(
              path: '/main/history',
              builder: (_, _) => const Text('History page'),
            ),
            GoRoute(
              path: '/main/report',
              builder: (_, _) => const Text('Report page'),
            ),
            GoRoute(
              path: '/main/settings',
              builder: (_, _) => const Text('Settings page'),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.text('ประวัติ'));
    await tester.pumpAndSettle();
    expect(find.text('History page'), findsOneWidget);
  });
}
