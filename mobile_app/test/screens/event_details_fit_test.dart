import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/screens/app/events/details.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/mock_data_service.dart';
import 'package:mobile_app/widgets/route_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService.mockMode = true;
    MockDataService().clearEventWaypoints();
  });

  tearDown(() {
    ApiService.mockMode = false;
    MockDataService().clearEventWaypoints();
  });

  Widget buildTestApp(int eventId, {Future<XFile?> Function()? pickFitFile}) {
    return MaterialApp(
      home: EventDetailsScreen(
        eventId: eventId,
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
              name: 'event.fit',
              path: 'event.fit',
            ),
      ),
    );
  }

  group('EventDetailsScreen past event FIT track & distribution tests', () {
    testWidgets(
      'past event allows organizer to add FIT track and displays RouteMap',
      (tester) async {
        final initialActivities =
            (await ActivityService().getActivities()).length;

        // Event 104 is a past event organized by current user in mock data
        await tester.pumpWidget(buildTestApp(104));
        await tester.pumpAndSettle();

        expect(find.text('Past Campus Welcome Run'), findsOneWidget);
        expect(find.text('Ajouter le tracé GPS (.fit)'), findsOneWidget);
        expect(find.byType(RouteMap), findsNothing);

        // Tap import track button
        await tester.tap(find.text('Ajouter le tracé GPS (.fit)'));
        await tester.pumpAndSettle();

        // RouteMap is now displayed!
        expect(find.byType(RouteMap), findsOneWidget);
        expect(find.text('Tracé GPS'), findsOneWidget);
        expect(find.text('Ajouter le tracé GPS (.fit)'), findsNothing);

        // Verify activity was created and distributed
        final afterActivities =
            (await ActivityService().getActivities()).length;
        expect(afterActivities, greaterThan(initialActivities));
      },
    );

    testWidgets('upcoming event shows Join/Leave instead of add track button', (
      tester,
    ) async {
      // Event 101 is an upcoming event
      await tester.pumpWidget(buildTestApp(101));
      await tester.pumpAndSettle();

      expect(find.text('Sunset Lake Trail Run'), findsOneWidget);
      expect(find.text('Ajouter le tracé GPS (.fit)'), findsNothing);
      expect(find.text('Leave Event'), findsOneWidget);
    });

    testWidgets('cancelling FIT track selection does nothing', (tester) async {
      await tester.pumpWidget(buildTestApp(104, pickFitFile: () async => null));
      await tester.pumpAndSettle();

      expect(find.text('Ajouter le tracé GPS (.fit)'), findsOneWidget);

      await tester.tap(find.text('Ajouter le tracé GPS (.fit)'));
      await tester.pumpAndSettle();

      expect(find.text('Ajouter le tracé GPS (.fit)'), findsOneWidget);
      expect(find.byType(RouteMap), findsNothing);
    });
  });
}
