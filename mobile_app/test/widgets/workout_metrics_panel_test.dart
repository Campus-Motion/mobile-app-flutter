import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/widgets/activity_card.dart';
import 'package:mobile_app/widgets/app_card.dart';
import 'package:mobile_app/widgets/stat_item.dart';
import 'package:mobile_app/widgets/workout_metrics_panel.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(24), child: child),
  ),
);

void main() {
  group('WorkoutMetricsPanel', () {
    testWidgets('composes AppCard and StatItem with MM:SS and pace', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const WorkoutMetricsPanel(
            elapsed: Duration(minutes: 17, seconds: 30),
            distanceKm: 3.5,
            status: WorkoutStatus.recording,
            sportType: 'run',
          ),
        ),
      );

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.byType(StatItem), findsNWidgets(2));
      expect(find.text('17:30'), findsOneWidget);
      expect(find.text('Elapsed time'), findsOneWidget);
      expect(find.text('3.50'), findsOneWidget);
      expect(find.text('km'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('5:00'), findsOneWidget);
      expect(find.text('min/km'), findsOneWidget);
      expect(find.text('Avg pace'), findsOneWidget);
      expect(find.text('Recording'), findsOneWidget);
      expect(find.byIcon(ActivityCard.getActivityIcon('run')), findsOneWidget);
    });

    testWidgets('formats HH:MM:SS when elapsed is one hour or more', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const WorkoutMetricsPanel(
            elapsed: Duration(hours: 1, minutes: 2, seconds: 9),
            distanceKm: 10.0,
          ),
        ),
      );

      expect(find.text('01:02:09'), findsOneWidget);
      expect(find.text('10.00'), findsOneWidget);
    });

    testWidgets('displays fallback pace and zeroed MM:SS when idle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const WorkoutMetricsPanel(
            elapsed: Duration(minutes: 5, seconds: 7),
            distanceKm: 0.0,
            status: WorkoutStatus.idle,
          ),
        ),
      );

      expect(find.text('05:07'), findsOneWidget);
      expect(find.text('0.00'), findsOneWidget);
      expect(find.text('--:--'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
    });

    testWidgets('displays Paused badge and explicit pace when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const WorkoutMetricsPanel(
            elapsed: Duration(minutes: 10),
            distanceKm: 2.0,
            paceMinPerKm: 4.5,
            status: WorkoutStatus.paused,
          ),
        ),
      );

      expect(find.text('Paused'), findsOneWidget);
      expect(find.text('4:30'), findsOneWidget);
    });

    testWidgets('renders without overflow on a 320px wide screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          const WorkoutMetricsPanel(
            elapsed: Duration(hours: 1, minutes: 23, seconds: 45),
            distanceKm: 12.34,
            status: WorkoutStatus.recording,
            sportType: 'cycle',
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
