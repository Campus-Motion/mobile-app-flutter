import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/screens/app/events/details.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/auth_service.dart';

void main() {
  setUp(() async {
    ApiService.mockMode = true;
    await AuthService().enterDemoMode();
  });

  tearDown(() {
    ApiService.mockMode = false;
  });

  group('EventDetailsScreen Tests', () {
    testWidgets('shows error state when eventId is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EventDetailsScreen(eventId: null),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invalid or missing event ID.'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });

    testWidgets('shows error state when eventId is invalid (<= 0)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EventDetailsScreen(eventId: -1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invalid or missing event ID.'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });

    testWidgets('renders event details, body, distance, metrics, and participants in mock mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EventDetailsScreen(eventId: 101),
        ),
      );
      await tester.pumpAndSettle();

      // Title & header
      expect(find.text('Sunset Lake Trail Run'), findsOneWidget);
      expect(find.text('Event Details'), findsOneWidget);

      // Body (description)
      expect(
        find.text('Join students for a relaxed 5km evening jog along Lake Geneva starting from Centre Sportif Dorigny.'),
        findsOneWidget,
      );

      // Distance (5000m -> 5.0 km)
      expect(find.text('5.0'), findsOneWidget);
      expect(find.text('km'), findsOneWidget);

      // Participants section & list
      expect(find.textContaining('Participants'), findsWidgets);
      expect(find.text('Robin.Doe'), findsOneWidget);
      expect(find.text('Camille.B'), findsOneWidget);

      // Initial join state: Robin.Doe is already enrolled in 101
      expect(find.text('Leave Event'), findsOneWidget);
    });

    testWidgets('initial join state is not enrolled for event 102', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EventDetailsScreen(eventId: 102),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Morning Campus Interval Training'), findsOneWidget);
      expect(find.text('Join Event'), findsOneWidget);
    });

    testWidgets('toggles join and leave event with state and participant count updates', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EventDetailsScreen(eventId: 102),
        ),
      );
      await tester.pumpAndSettle();

      // Initially not joined
      expect(find.text('Join Event'), findsOneWidget);
      final initialCountText = find.text('6');
      expect(initialCountText, findsOneWidget);

      // Tap Join Event
      await tester.tap(find.text('Join Event'));
      await tester.pumpAndSettle();

      // Now joined: button changes to Leave Event, count becomes 7
      expect(find.text('Leave Event'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Successfully joined the event!'), findsOneWidget);
      expect(find.text('Robin.Doe'), findsOneWidget);

      // Tap Leave Event
      await tester.tap(find.text('Leave Event'));
      await tester.pumpAndSettle();

      // Now left: button changes back to Join Event, count decrements to 6
      expect(find.text('Join Event'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('You have left the event.'), findsOneWidget);
    });

    testWidgets('route AppRoutes.eventDetails opens screen with int argument', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          initialRoute: '/',
          routes: {
            '/': (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.eventDetails,
                      arguments: 101,
                    ),
                    child: const Text('Open Event'),
                  ),
                ),
          },
        ),
      );

      await tester.tap(find.text('Open Event'));
      await tester.pumpAndSettle();

      expect(find.text('Sunset Lake Trail Run'), findsOneWidget);
      expect(find.text('Event Details'), findsOneWidget);
    });

    testWidgets('route AppRoutes.eventDetails with missing argument shows error state instead of crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          initialRoute: '/',
          routes: {
            '/': (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.eventDetails,
                      arguments: null,
                    ),
                    child: const Text('Open Broken Event'),
                  ),
                ),
          },
        ),
      );

      await tester.tap(find.text('Open Broken Event'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid or missing event ID.'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });
  });
}
