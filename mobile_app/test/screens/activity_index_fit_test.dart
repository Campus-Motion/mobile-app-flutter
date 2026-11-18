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

  Widget buildTestApp({Future<XFile?> Function()? pickFitFile}) {
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
        ),
        AppRoutes.heatmaps: (_) => const HeatmapScreen(),
        AppRoutes.dashboard: (_) => const Scaffold(body: Text('Dashboard')),
        AppRoutes.social: (_) => const Scaffold(body: Text('Social')),
        AppRoutes.profile: (_) => const Scaffold(body: Text('Profile')),
      },
    );
  }

  group('ActivityIndexScreen FIT import & heatmaps tests', () {
    testWidgets('renders "Mes Heatmap" button and navigates on tap', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Mes Heatmap'), findsOneWidget);

      // Tap button
      await tester.tap(find.text('Mes Heatmap'));
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
      expect(find.text('Importer un fichier .FIT'), findsOneWidget);

      // Tap activity type dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Check standard watch categories are present
      expect(find.text('Course à pied (run)'), findsWidgets);
      expect(find.text('Cyclisme (cycle)'), findsWidgets);
      expect(find.text('Marche (walk)'), findsWidgets);
      expect(find.text('Randonnée (hike)'), findsWidgets);
      expect(find.text('Natation (swim)'), findsWidgets);
      expect(find.text('Autre (other)'), findsWidgets);

      // Climbing is removed per specification
      expect(find.text('Climbing'), findsNothing);

      // Close dropdown by tapping outside
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
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
      await tester.tap(find.text('Importer un fichier .FIT'));
      await tester.pumpAndSettle();

      // Warning banner must be visible because imported FIT is classified as "other"
      expect(
        find.textContaining('veuillez préciser votre sport'),
        findsOneWidget,
      );
      expect(find.text('Fichier .FIT importé'), findsOneWidget);

      // Select 'Cyclisme (cycle)' from dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cyclisme (cycle)').last);
      await tester.pumpAndSettle();

      // Warning disappears once a discipline is chosen
      expect(
        find.textContaining('veuillez préciser votre sport'),
        findsNothing,
      );
    });

    testWidgets('cancelling FIT file selection does nothing', (tester) async {
      await tester.pumpWidget(buildTestApp(pickFitFile: () async => null));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Importer un fichier .FIT'));
      await tester.pumpAndSettle();

      expect(find.text('Importer un fichier .FIT'), findsOneWidget);
      expect(
        find.textContaining('veuillez préciser votre sport'),
        findsNothing,
      );
    });
  });
}
