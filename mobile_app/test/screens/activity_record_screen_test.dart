import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/models/activity.dart';
import 'package:mobile_app/screens/app/activity/index.dart';
import 'package:mobile_app/screens/app/activity/record.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/widgets/app_button.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/sport_type_selector.dart';
import 'package:mobile_app/widgets/workout_control_bar.dart';
import 'package:mobile_app/widgets/workout_metrics_panel.dart';

void main() {
  setUp(() async {
    ApiService.mockMode = true;
    await AuthService().enterDemoMode();
  });

  tearDown(() {
    ApiService.mockMode = false;
  });

  group('ActivityRecordScreen', () {
    testWidgets(
      'navigating to AppRoutes.recordActivity renders ActivityRecordScreen inside MasterContainer',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            onGenerateRoute: AppRoutes.generateRoute,
            initialRoute: '/',
            routes: {
              '/': (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.recordActivity),
                    child: const Text('Open Record'),
                  ),
                ),
              ),
            },
          ),
        );

        await tester.tap(find.text('Open Record'));
        await tester.pumpAndSettle();

        expect(find.byType(ActivityRecordScreen), findsOneWidget);
        expect(find.byType(MasterContainer), findsOneWidget);
        expect(find.byType(SportTypeSelector), findsOneWidget);
        expect(find.byType(WorkoutMetricsPanel), findsOneWidget);
        expect(find.byType(WorkoutControlBar), findsOneWidget);
        expect(find.text('Ready'), findsOneWidget);
        expect(find.text('00:00'), findsOneWidget);
        expect(find.text('0.00'), findsOneWidget);
      },
    );

    testWidgets(
      'starts timer, updates elapsed time, distance and pace every second, and locks sport selection',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ActivityRecordScreen()),
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('sport_pill_cycle')),
        );
        await tester.pump();

        expect(
          tester
              .widget<SportTypeSelector>(find.byType(SportTypeSelector))
              .selectedType,
          'cycle',
        );
        expect(
          tester
              .widget<SportTypeSelector>(find.byType(SportTypeSelector))
              .enabled,
          isTrue,
        );

        await tester.tap(find.text('Start activity'));
        await tester.pump();

        expect(find.text('Recording'), findsOneWidget);
        expect(
          tester
              .widget<SportTypeSelector>(find.byType(SportTypeSelector))
              .enabled,
          isFalse,
        );

        await tester.tap(find.byKey(const ValueKey<String>('sport_pill_walk')));
        await tester.pump();
        expect(
          tester
              .widget<SportTypeSelector>(find.byType(SportTypeSelector))
              .selectedType,
          'cycle',
        );

        await tester.pump(const Duration(seconds: 1));
        expect(find.text('00:01'), findsOneWidget);
        expect(find.text('0.01'), findsOneWidget);
        expect(find.text('3:00'), findsOneWidget);

        await tester.pump(const Duration(seconds: 8));
        expect(find.text('00:09'), findsOneWidget);
        expect(find.text('0.05'), findsOneWidget);
        expect(find.text('3:00'), findsOneWidget);
      },
    );

    testWidgets(
      'pausing freezes elapsed time and distance; resuming continues from paused values',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ActivityRecordScreen()),
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('sport_pill_cycle')),
        );
        await tester.pump();
        await tester.tap(find.text('Start activity'));
        await tester.pump();

        await tester.pump(const Duration(seconds: 9));
        expect(find.text('00:09'), findsOneWidget);
        expect(find.text('0.05'), findsOneWidget);

        await tester.tap(find.text('Pause'));
        await tester.pump();

        expect(find.text('Paused'), findsOneWidget);
        expect(
          tester
              .widget<SportTypeSelector>(find.byType(SportTypeSelector))
              .enabled,
          isFalse,
        );

        await tester.pump(const Duration(seconds: 5));
        expect(find.text('00:09'), findsOneWidget);
        expect(find.text('0.05'), findsOneWidget);

        await tester.tap(find.text('Resume'));
        await tester.pump();

        expect(find.text('Recording'), findsOneWidget);
        await tester.pump(const Duration(seconds: 9));
        expect(find.text('00:18'), findsOneWidget);
        expect(find.text('0.10'), findsOneWidget);
        expect(find.text('3:00'), findsOneWidget);
      },
    );

    testWidgets(
      'back navigation during active or paused workout shows confirmation dialog',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            onGenerateRoute: AppRoutes.generateRoute,
            initialRoute: '/',
            routes: {
              '/': (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.recordActivity),
                    child: const Text('Open Record'),
                  ),
                ),
              ),
            },
          ),
        );

        // Idle state pops immediately without confirmation dialog.
        await tester.tap(find.text('Open Record'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        expect(find.byType(ActivityRecordScreen), findsNothing);

        // Recording state intercepts back navigation and can cancel.
        await tester.tap(find.text('Open Record'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Start activity'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();

        expect(find.text('Discard workout?'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.byType(ActivityRecordScreen), findsOneWidget);
        expect(find.text('Recording'), findsOneWidget);

        // Paused state also intercepts back navigation and discards when confirmed.
        await tester.tap(find.text('Pause'));
        await tester.pump();
        expect(find.text('Paused'), findsOneWidget);

        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();

        expect(find.text('Discard workout?'), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Discard'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ActivityRecordScreen), findsNothing);
      },
    );

    testWidgets(
      'disposing ActivityRecordScreen while recording cancels timer with no leaked timers',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ActivityRecordScreen()),
        );

        await tester.tap(find.text('Start activity'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        await tester.pumpAndSettle();

        expect(find.byType(ActivityRecordScreen), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ActivityIndexScreen Start activity button navigates to ActivityRecordScreen and reloads activities on return',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: const ActivityIndexScreen(),
            onGenerateRoute: AppRoutes.generateRoute,
          ),
        );
        await tester.pumpAndSettle();

        final startButton = find.widgetWithText(AppButton, 'Start activity');
        expect(startButton, findsOneWidget);

        await tester.tap(startButton);
        await tester.pumpAndSettle();

        expect(find.byType(ActivityRecordScreen), findsOneWidget);

        await ActivityService().createActivity(
          Activity(
            id: 0,
            title: 'Live Test Session',
            type: 'run',
            userId: 1,
            isPublic: false,
            createdAt: DateTime.now(),
            duration: 15.0,
            distanceKm: 2.5,
          ),
        );

        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();

        expect(find.byType(ActivityIndexScreen), findsOneWidget);
        expect(find.text('Live Test Session'), findsOneWidget);
      },
    );

    testWidgets(
      'paused Discard button resets session to Ready and Finish pops route',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            onGenerateRoute: AppRoutes.generateRoute,
            initialRoute: '/',
            routes: {
              '/': (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.recordActivity),
                    child: const Text('Open Record'),
                  ),
                ),
              ),
            },
          ),
        );

        await tester.tap(find.text('Open Record'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Start activity'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));

        await tester.tap(find.text('Pause'));
        await tester.pump();

        await tester.tap(find.text('Discard'));
        await tester.pump();

        expect(find.text('Ready'), findsOneWidget);
        expect(find.text('00:00'), findsOneWidget);
        expect(find.text('0.00'), findsOneWidget);
        expect(
          tester
              .widget<SportTypeSelector>(find.byType(SportTypeSelector))
              .enabled,
          isTrue,
        );

        await tester.tap(find.text('Start activity'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        await tester.tap(find.text('Pause'));
        await tester.pump();

        await tester.tap(find.text('Finish'));
        await tester.pumpAndSettle();

        expect(find.byType(ActivityRecordScreen), findsNothing);
      },
    );

    testWidgets('renders without overflow on a 320px wide screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: ActivityRecordScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
