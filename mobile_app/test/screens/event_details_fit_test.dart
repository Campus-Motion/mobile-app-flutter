import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/screens/app/activity/details.dart';
import 'package:mobile_app/screens/app/events/details.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/mock_data_service.dart';
import 'package:mobile_app/widgets/route_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService.mockMode = true;
    MockDataService().resetMockActivities();
    MockDataService().clearEventWaypoints();
  });

  tearDown(() {
    MockDataService().resetMockActivities();
    MockDataService().clearEventWaypoints();
    ApiService.mockMode = false;
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
        expect(find.text('Add GPS route (.fit)'), findsOneWidget);
        expect(find.byType(RouteMap), findsNothing);
        expect(find.text('Pace'), findsNothing);
        expect(find.text('Elevation'), findsNothing);

        // Tap import track button
        await tester.tap(find.text('Add GPS route (.fit)'));
        await tester.pumpAndSettle();

        // RouteMap and 4-quadrant FIT metrics are now displayed!
        expect(find.byType(RouteMap), findsOneWidget);
        expect(find.text('GPS Route'), findsOneWidget);
        expect(find.text('Distance'), findsOneWidget);
        expect(find.text('Duration'), findsOneWidget);
        expect(find.text('Pace'), findsOneWidget);
        expect(find.text('Elevation'), findsOneWidget);
        expect(find.text('Add GPS route (.fit)'), findsNothing);

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
      expect(find.text('Add GPS route (.fit)'), findsNothing);
      expect(find.text('Leave Event'), findsOneWidget);
    });

    testWidgets('cancelling FIT track selection does nothing', (tester) async {
      await tester.pumpWidget(buildTestApp(104, pickFitFile: () async => null));
      await tester.pumpAndSettle();

      expect(find.text('Add GPS route (.fit)'), findsOneWidget);

      await tester.tap(find.text('Add GPS route (.fit)'));
      await tester.pumpAndSettle();

      expect(find.text('Add GPS route (.fit)'), findsOneWidget);
      expect(find.byType(RouteMap), findsNothing);
    });

    testWidgets(
      'participant cannot import FIT track, but receives activity with GPS waypoints after organizer imports it',
      (tester) async {
        // 1. Switch to Participant profile (Camille.B, userId: 2)
        await AuthService().switchDemoUser(2);
        final participantBefore = await ActivityService().getActivities();
        expect(participantBefore, isEmpty);

        // Participant opens past Event 104: must NOT see "Add GPS route (.fit)"
        await tester.pumpWidget(buildTestApp(104));
        await tester.pumpAndSettle();

        expect(find.text('Past Campus Welcome Run'), findsOneWidget);
        expect(find.text('Add GPS route (.fit)'), findsNothing);

        // 2. Switch to Organizer profile (Robin.Doe, userId: 1) and import FIT
        await AuthService().switchDemoUser(1);
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('organizer-view'),
            home: EventDetailsScreen(
              eventId: 104,
              pickFitFile: () async => XFile.fromData(
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
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Add GPS route (.fit)'), findsOneWidget);
        await tester.tap(find.text('Add GPS route (.fit)'));
        await tester.pumpAndSettle();
        expect(find.byType(RouteMap), findsOneWidget);

        // 3. Switch back to Participant profile (Camille.B, userId: 2)
        await AuthService().switchDemoUser(2);
        final participantAfter = await ActivityService().getActivities();
        expect(participantAfter.length, 1);
        expect(participantAfter.first.title, 'Past Campus Welcome Run');
        expect(participantAfter.first.userId, 2);
        expect(participantAfter.first.hasFit, isTrue);
        expect(participantAfter.first.isFromEvent, isTrue);

        final participantWaypoints = await ActivityService().getWaypoints(
          participantAfter.first.id,
        );
        expect(participantWaypoints.length, greaterThanOrEqualTo(2));

        // 4. Open ActivityDetailsScreen for the distributed activity and verify "Event" badge
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('participant-activity-details'),
            home: ActivityDetailsScreen(
              activityId: participantAfter.first.id,
              initialActivity: participantAfter.first,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Event'), findsOneWidget);
        expect(find.byIcon(Icons.event), findsOneWidget);
      },
    );
  });
}
