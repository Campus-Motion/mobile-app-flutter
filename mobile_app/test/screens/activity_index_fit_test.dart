import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/screens/app/activity/index.dart';
import 'package:mobile_app/screens/app/heatmap/index.dart';
import 'package:mobile_app/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService.mockMode = true;
  });

  tearDown(() {
    ApiService.mockMode = false;
  });

  Widget buildTestApp({
    Future<XFile?> Function()? pickFitFile,
    Future<List<XFile>?> Function()? pickFitFolder,
  }) {
    return MaterialApp(
      initialRoute: AppRoutes.trail,
      routes: {
        AppRoutes.trail: (_) => ActivityIndexScreen(
          pickFitFile:
              pickFitFile ??
              () async => XFile.fromData(
                Uint8List.fromList([
                  0x0E,
                  0x10,
                  0x47,
                  0x08,
                  0x00,
                  0x00,
                  0x00,
                  0x00,
                  0x2E,
                  0x46,
                  0x49,
                  0x54,
                  0x00,
                  0x00,
                ]),
                name: 'activity.fit',
                path: 'activity.fit',
              ),
          pickFitFolder: pickFitFolder,
        ),
        AppRoutes.heatmaps: (_) => const HeatmapScreen(),
        AppRoutes.dashboard: (_) => const Scaffold(body: Text('Dashboard')),
        AppRoutes.social: (_) => const Scaffold(body: Text('Social')),
        AppRoutes.profile: (_) => const Scaffold(body: Text('Profile')),
      },
    );
  }

  group('ActivityIndexScreen FIT import & heatmaps tests', () {
    testWidgets('renders "My Heatmaps" button and navigates on tap', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('My Heatmaps'), findsOneWidget);

      // Tap button
      await tester.tap(find.text('My Heatmaps'));
      await tester.pumpAndSettle();

      expect(find.byType(HeatmapScreen), findsOneWidget);
    });

    testWidgets('log activity dialog has harmonized sports and FIT import', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap FAB to open dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Log Activity'), findsOneWidget);
      expect(find.text('Import a .FIT file'), findsOneWidget);

      // Tap activity type dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Check standard watch categories are present
      expect(find.text('Running (run)'), findsWidgets);
      expect(find.text('Cycling (cycle)'), findsWidgets);
      expect(find.text('Walking (walk)'), findsWidgets);
      expect(find.text('Hiking (hike)'), findsWidgets);
      expect(find.text('Swimming (swim)'), findsWidgets);
      expect(find.text('Other (other)'), findsWidgets);

      // Climbing is removed per specification
      expect(find.text('Climbing'), findsNothing);

      // Close dropdown by tapping outside
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Check duration and distance fields
      expect(
        find.widgetWithText(TextFormField, 'Duration (minutes)'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Distance (km)'),
        findsOneWidget,
      );
    });

    testWidgets('manually logging activity with distance creates activity', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Duration (minutes)'),
        '30',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Distance (km)'),
        '5.2',
      );

      await tester.tap(find.text('Save Activity'));
      await tester.pumpAndSettle();

      expect(find.text('Activity logged successfully!'), findsOneWidget);
    });

    testWidgets('importing FIT file displays warning if sport is "other"', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Tap import FIT button
      await tester.tap(find.text('Import a .FIT file'));
      await tester.pumpAndSettle();

      // Warning banner must be visible because imported FIT is classified as "other"
      expect(find.textContaining('please specify your sport'), findsOneWidget);
      expect(find.text('FIT file imported'), findsOneWidget);

      // Select 'Cycling (cycle)' from dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cycling (cycle)').last);
      await tester.pumpAndSettle();

      // Warning disappears once a discipline is chosen
      expect(find.textContaining('please specify your sport'), findsNothing);
    });

    testWidgets('cancelling FIT file selection does nothing', (tester) async {
      await tester.pumpWidget(buildTestApp(pickFitFile: () async => null));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Import a .FIT file'));
      await tester.pumpAndSettle();

      expect(find.text('Import a .FIT file'), findsOneWidget);
      expect(find.textContaining('please specify your sport'), findsNothing);
    });

    testWidgets(
      'importing FIT with running sport autocompletes run and saves without error',
      (tester) async {
        final runningFitBytes = Uint8List.fromList([
          14, 0x10, 0x88, 0x08,
          11, 0x00, 0x00, 0x00, // 11 data bytes
          0x2E, 0x46, 0x49, 0x54, // .FIT
          0x00, 0x00,
          // Def msg for local 0 -> global 12 (sport)
          0x40, 0x00, 0x00, 0x0C, 0x00, 0x01,
          0x00, 0x01, 0x00,
          // Data msg for local 0: sport = 1 (run)
          0x00, 0x01,
        ]);

        await tester.pumpWidget(
          buildTestApp(
            pickFitFile: () async => XFile.fromData(
              runningFitBytes,
              name: 'run.fit',
              path: 'run.fit',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Import a .FIT file'));
        await tester.pumpAndSettle();

        // No warning because sport is 'run'
        expect(find.textContaining('please specify your sport'), findsNothing);

        // Save activity (tests handlePut and ensures no TypeError is thrown)
        await tester.tap(find.text('Save Activity'));
        await tester.pumpAndSettle();

        // Confirms dialog is dismissed and success snackbar appears
        expect(find.text('Activity logged successfully!'), findsOneWidget);
      },
    );

    testWidgets(
      'importing a FIT folder ignores non-.fit files and creates an activity for each .fit file',
      (tester) async {
        final fitBytes = Uint8List.fromList([
          14,
          0x10,
          0x88,
          0x08,
          11,
          0x00,
          0x00,
          0x00,
          0x2E,
          0x46,
          0x49,
          0x54,
          0x00,
          0x00,
          0x40,
          0x00,
          0x00,
          0x0C,
          0x00,
          0x01,
          0x00,
          0x01,
          0x00,
          0x00,
          0x01,
        ]);

        await tester.pumpWidget(
          buildTestApp(
            pickFitFolder: () async => [
              XFile.fromData(fitBytes, name: 'run1.fit', path: 'run1.fit'),
              XFile.fromData(
                Uint8List.fromList([1, 2, 3]),
                name: 'readme.txt',
                path: 'readme.txt',
              ),
              XFile.fromData(fitBytes, name: 'run2.FIT', path: 'run2.FIT'),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(find.text('Import a .FIT folder'), findsOneWidget);

        await tester.tap(find.text('Import a .FIT folder'));
        await tester.pumpAndSettle();

        expect(
          find.text('Imported 2 .FIT activities (1 non-.FIT file ignored).'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'importing a folder without any .fit files shows informative message',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            pickFitFolder: () async => [
              XFile.fromData(
                Uint8List.fromList([1, 2, 3]),
                name: 'image.png',
                path: 'image.png',
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Import a .FIT folder'));
        await tester.pumpAndSettle();

        expect(
          find.text('No .FIT files found in the selected folder.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Past Group Events checkbox filters only events in which the user participated',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Switch to Events tab
        await tester.tap(find.text('Events'));
        await tester.pumpAndSettle();

        expect(find.text('Past Group Events'), findsOneWidget);
        expect(find.text('Participated only'), findsOneWidget);

        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, isFalse);

        // By default (unchecked), both past events (104 and 105) are shown
        expect(find.text('Past Campus Welcome Run'), findsOneWidget);
        expect(find.text('Lakeside Track Recovery Session'), findsOneWidget);

        // Check "Participated only" filter
        await tester.tap(find.text('Participated only'));
        await tester.pumpAndSettle();

        // Now only Event 104 (where Robin.Doe participated) is shown
        expect(find.text('Past Campus Welcome Run'), findsOneWidget);
        expect(find.text('Lakeside Track Recovery Session'), findsNothing);
      },
    );
  });
}
