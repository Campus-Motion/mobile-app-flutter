import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/widgets/bottom_bar.dart';

class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<String?> pushedRoutes = [];
  final List<String?> replacedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replacedRoutes.add(newRoute?.settings.name);
  }
}

void main() {
  group('CampusMotionBottomBar Tests', () {
    test('AppRoutes.tabRoute maps indices to tab route names', () {
      expect(AppRoutes.tabRoute(0), AppRoutes.dashboard);
      expect(AppRoutes.tabRoute(1), AppRoutes.trail);
      expect(AppRoutes.tabRoute(2), AppRoutes.social);
      expect(AppRoutes.tabRoute(3), AppRoutes.profile);
      expect(AppRoutes.tabRoute(99), AppRoutes.dashboard);
    });

    testWidgets(
      'uses AppColors.primary for active tab and textMuted for inactive',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: CampusMotionBottomBar(currentIndex: 1),
            ),
          ),
        );

        final sportText = tester.widget<Text>(find.text('Sport'));
        final homeText = tester.widget<Text>(find.text('Home'));
        final sportIcon = tester.widget<Icon>(
          find.byIcon(Icons.sports_soccer_rounded),
        );
        final homeIcon = tester.widget<Icon>(find.byIcon(Icons.home_rounded));

        expect(sportText.style?.color, AppColors.primary);
        expect(sportText.style?.fontWeight, FontWeight.bold);
        expect(sportIcon.color, AppColors.primary);

        expect(homeText.style?.color, AppColors.textMuted);
        expect(homeText.style?.fontWeight, FontWeight.normal);
        expect(homeIcon.color, AppColors.textMuted);
      },
    );

    testWidgets('tapping the active tab does not navigate', (tester) async {
      final observer = _RecordingNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          initialRoute: AppRoutes.dashboard,
          routes: {
            AppRoutes.dashboard: (_) => const Scaffold(
              body: Text('Dashboard Screen'),
              bottomNavigationBar: CampusMotionBottomBar(currentIndex: 0),
            ),
            AppRoutes.trail: (_) => const Scaffold(body: Text('Sport Screen')),
          },
        ),
      );

      observer.pushedRoutes.clear();
      observer.replacedRoutes.clear();

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(observer.pushedRoutes, isEmpty);
      expect(observer.replacedRoutes, isEmpty);
      expect(find.text('Dashboard Screen'), findsOneWidget);
    });

    testWidgets(
      'tapping another tab replaces the current route with the target tab route',
      (tester) async {
        final observer = _RecordingNavigatorObserver();

        await tester.pumpWidget(
          MaterialApp(
            navigatorObservers: [observer],
            initialRoute: AppRoutes.dashboard,
            routes: {
              AppRoutes.dashboard: (_) => const Scaffold(
                body: Text('Dashboard Screen'),
                bottomNavigationBar: CampusMotionBottomBar(currentIndex: 0),
              ),
              AppRoutes.trail: (_) => const Scaffold(
                body: Text('Sport Screen'),
                bottomNavigationBar: CampusMotionBottomBar(currentIndex: 1),
              ),
              AppRoutes.social: (_) => const Scaffold(
                body: Text('Social Screen'),
                bottomNavigationBar: CampusMotionBottomBar(currentIndex: 2),
              ),
              AppRoutes.profile: (_) => const Scaffold(
                body: Text('Profile Screen'),
                bottomNavigationBar: CampusMotionBottomBar(currentIndex: 3),
              ),
            },
          ),
        );

        observer.pushedRoutes.clear();
        observer.replacedRoutes.clear();

        await tester.tap(find.text('Sport'));
        await tester.pumpAndSettle();

        expect(observer.pushedRoutes, isEmpty);
        expect(observer.replacedRoutes, [AppRoutes.trail]);
        expect(find.text('Sport Screen'), findsOneWidget);

        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        expect(observer.pushedRoutes, isEmpty);
        expect(observer.replacedRoutes, [AppRoutes.trail, AppRoutes.profile]);
        expect(find.text('Profile Screen'), findsOneWidget);
      },
    );
  });
}
