import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/screens/app/activity/details.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/auth_service.dart';
import '../helpers/fake_tile_provider.dart';

void main() {
  setUp(() async {
    ApiService.mockMode = true;
    await AuthService().enterDemoMode();
  });

  tearDown(() {
    ApiService.mockMode = false;
  });

  group('ActivityDetailsScreen Tests', () {
    testWidgets(
      'shows error state when activityId is null and no initial activity',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ActivityDetailsScreen(activityId: null)),
        );
        await tester.pumpAndSettle();

        expect(find.text('No activity ID was provided.'), findsOneWidget);
        expect(find.text('Go Back'), findsOneWidget);
      },
    );

    testWidgets('shows error state when activityId is invalid', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ActivityDetailsScreen(activityId: -1)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invalid activity ID'), findsOneWidget);
    });

    testWidgets('renders activity details, metrics, and route map in mock mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityDetailsScreen(
            activityId: 201,
            tileProvider: FakeTileProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title
      expect(find.text('Morning Campus Run'), findsOneWidget);

      // Metrics
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('Pace'), findsOneWidget);
      expect(find.text('6.2'), findsOneWidget);
      expect(find.text('35m'), findsOneWidget);

      // Route Map
      expect(find.text('GPS Route'), findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.textContaining('GPS checkpoints recorded'), findsOneWidget);

      // Body / notes
      expect(
        find.text(
          'Nice 6.2km loop through EPFL Innovation Park down to the lake shores.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('route AppRoutes.activityDetails opens with int argument', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.activityDetails,
                  arguments: 201,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(ActivityDetailsScreen), findsOneWidget);
      expect(find.text('Morning Campus Run'), findsOneWidget);
    });
  });
}
