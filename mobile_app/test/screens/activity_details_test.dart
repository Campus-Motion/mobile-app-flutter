import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/screens/app/activity/details.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/mock_data_service.dart';
import '../helpers/fake_tile_provider.dart';

void main() {
  setUp(() async {
    ApiService.mockMode = true;
    MockDataService().resetMockActivities();
    await AuthService().enterDemoMode();
  });

  tearDown(() {
    ApiService.mockMode = false;
    MockDataService().resetMockActivities();
  });

  Uint8List buildMockFitBytes() {
    return Uint8List.fromList([
      14, 0x10, 0x88, 0x08,
      11, 0x00, 0x00, 0x00,
      0x2E, 0x46, 0x49, 0x54,
      0x00, 0x00,
      0x40, 0x00, 0x00, 0x0C, 0x00, 0x01,
      0x00, 0x01, 0x00,
      0x00, 0x01, // sport = run
    ]);
  }

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

    testWidgets(
      'activity without FIT track shows encouragement message on grey background and no RouteMap',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: ActivityDetailsScreen(
              activityId: 203,
              tileProvider: FakeTileProvider(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Campus Trail Walk'), findsOneWidget);
        expect(find.byType(FlutterMap), findsNothing);
        expect(find.text('No GPS route recorded'), findsOneWidget);
        expect(
          find.textContaining('Attach a .fit file to this activity'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(OutlinedButton, 'Attach a .fit file'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'editing activity with FIT locks sport dropdown but allows modifying title and visibility',
      (tester) async {
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

        // Tap Edit Icon
        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();

        expect(find.text('Edit activity'), findsOneWidget);
        expect(find.text('Sport locked by FIT file'), findsOneWidget);
        expect(find.text('Duration locked by FIT file'), findsOneWidget);
        expect(find.text('Distance locked by FIT file'), findsOneWidget);

        // Update Title
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Activity Title'),
          'Morning Campus Run Renamed',
        );
        await tester.pumpAndSettle();

        // Save
        await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
        await tester.pumpAndSettle();

        expect(find.text('Morning Campus Run Renamed'), findsOneWidget);
        expect(find.text('Activity updated successfully.'), findsOneWidget);
      },
    );

    testWidgets(
      'editing activity without FIT allows modifying sport type, duration, and distance',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: ActivityDetailsScreen(
              activityId: 204,
              tileProvider: FakeTileProvider(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Edit Icon
        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();

        // Dropdown and fields are not locked
        expect(find.text('Sport locked by FIT file'), findsNothing);
        expect(find.text('Duration locked by FIT file'), findsNothing);
        expect(find.text('Distance locked by FIT file'), findsNothing);

        // Change sport to Cycling
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cycling (cycle)').last);
        await tester.pumpAndSettle();

        // Change duration and distance
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Duration (minutes)'),
          '45',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Distance (km)'),
          '5.5',
        );
        await tester.pumpAndSettle();

        // Save
        await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
        await tester.pumpAndSettle();

        expect(find.text('Activity updated successfully.'), findsOneWidget);
        expect(find.text('5.5'), findsOneWidget);
        expect(find.text('45m'), findsOneWidget);
      },
    );

    testWidgets(
      'adding a FIT file to activity without FIT track associates file and reveals RouteMap',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: ActivityDetailsScreen(
              activityId: 203,
              tileProvider: FakeTileProvider(),
              pickFitFile: () async => XFile.fromData(
                buildMockFitBytes(),
                name: 'workout.fit',
                path: 'workout.fit',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially no map
        expect(find.byType(FlutterMap), findsNothing);

        // Tap Add FIT file button
        await tester.tap(
          find.widgetWithText(OutlinedButton, 'Attach a .fit file'),
        );
        await tester.pumpAndSettle();

        expect(find.text('FIT file attached successfully.'), findsOneWidget);
        expect(find.byType(FlutterMap), findsOneWidget);
      },
    );

    testWidgets('delete activity prompts confirmation dialog and deletes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityDetailsScreen(
            activityId: 204,
            tileProvider: FakeTileProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Delete Icon
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete activity'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete "Lakeside Walk"?'),
        findsOneWidget,
      );

      // Confirm delete
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      // Activity should be deleted
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
