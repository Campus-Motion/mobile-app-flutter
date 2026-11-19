import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/models/activity.dart';
import 'package:mobile_app/screens/app/activity/index.dart';
import 'package:mobile_app/screens/app/activity/record.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/widgets/activity_card.dart';
import 'package:mobile_app/widgets/app_button.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/sport_type_selector.dart';
import 'package:mobile_app/widgets/stat_item.dart';
import 'package:mobile_app/widgets/workout_control_bar.dart';
import 'package:mobile_app/widgets/workout_metrics_panel.dart';

class _FakeActivityService implements ActivityService {
  final Future<Activity> Function(Activity activity) onCreate;
  int createCalls = 0;

  _FakeActivityService(this.onCreate);

  @override
  Future<Activity> createActivity(Activity activity) {
    createCalls++;
    return onCreate(activity);
  }

  @override
  Future<void> deleteActivity(int id) async {}

  @override
  Future<List<Activity>> getActivities({
    int? limit,
    int? cursor,
    String? type,
    bool? public,
  }) async => [];

  @override
  Future<Activity> getActivity(int id) => throw UnimplementedError();

  @override
  Future<Activity> updateActivity(int id, Map<String, dynamic> body) =>
      throw UnimplementedError();
}

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
      'paused Discard button resets session to Ready and Finish opens post-workout summary',
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

        expect(find.byType(ActivityRecordScreen), findsOneWidget);
        expect(find.byType(StatItem), findsNWidgets(3));
        expect(find.text('Duration'), findsOneWidget);
        expect(find.text('Distance'), findsOneWidget);
        expect(find.text('Avg pace'), findsOneWidget);
        expect(find.text('Make activity public'), findsOneWidget);
        expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isFalse,
        );
        expect(find.text('Save activity'), findsOneWidget);
        expect(find.text('Discard workout'), findsOneWidget);
      },
    );

    test(
      'ActivityCard.getDefaultActivityTitle formats morning, afternoon and evening titles',
      () {
        expect(
          ActivityCard.getDefaultActivityTitle(
            'run',
            now: DateTime(2026, 11, 18, 8, 30),
          ),
          'Morning Run',
        );
        expect(
          ActivityCard.getDefaultActivityTitle(
            'cycle',
            now: DateTime(2026, 11, 18, 14, 0),
          ),
          'Afternoon Cycle',
        );
        expect(
          ActivityCard.getDefaultActivityTitle(
            'swim',
            now: DateTime(2026, 11, 18, 19, 45),
          ),
          'Evening Swim',
        );
        expect(
          ActivityCard.getDefaultActivityTitle(
            '',
            now: DateTime(2026, 11, 18, 9, 0),
          ),
          'Morning Workout',
        );
      },
    );

    testWidgets(
      'finishing and saving creates private-by-default activity in MockDataService and shows it at top of Activities tab',
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

        await tester.tap(find.widgetWithText(AppButton, 'Start activity'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('sport_pill_cycle')),
        );
        await tester.pump();

        await tester.tap(find.text('Start activity'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 9));

        await tester.tap(find.text('Pause'));
        await tester.pump();
        await tester.tap(find.text('Finish'));
        await tester.pumpAndSettle();

        expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isFalse,
        );

        await tester.enterText(
          find.byKey(const ValueKey<String>('workout_title_field')),
          'Lakefront Sprint Ride',
        );
        await tester.enterText(
          find.byKey(const ValueKey<String>('workout_notes_field')),
          'Strong tailwind near Dorigny',
        );

        final saveButton = find.widgetWithText(AppButton, 'Save activity');
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(find.byType(ActivityRecordScreen), findsNothing);
        expect(find.byType(ActivityIndexScreen), findsOneWidget);
        expect(find.text('Lakefront Sprint Ride'), findsOneWidget);
        expect(find.text('Strong tailwind near Dorigny'), findsOneWidget);

        expect(
          tester.getTopLeft(find.text('Lakefront Sprint Ride')).dy,
          lessThan(tester.getTopLeft(find.text('Morning Campus Run')).dy),
        );

        final activities = await ActivityService().getActivities();
        final saved = activities.first;
        expect(saved.title, 'Lakefront Sprint Ride');
        expect(saved.type, 'cycle');
        expect(saved.isPublic, isFalse);
        expect(saved.body, 'Strong tailwind near Dorigny');
        expect(saved.duration, 1.0);
        expect(saved.distanceKm, closeTo(0.05, 0.005));
      },
    );

    testWidgets(
      'toggling Make activity public persists isPublic true and uses elapsed minutes when >= 60s',
      (tester) async {
        Activity? submitted;
        final fakeService = _FakeActivityService((activity) async {
          submitted = activity;
          return activity;
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (_) =>
                          ActivityRecordScreen(activityService: fakeService),
                    ),
                  ),
                  child: const Text('Open Record'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Record'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Start activity'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 90));
        await tester.tap(find.text('Pause'));
        await tester.pump();
        await tester.tap(find.text('Finish'));
        await tester.pumpAndSettle();

        final toggle = find.byType(SwitchListTile);
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pump();

        expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isTrue,
        );

        final saveButton = find.widgetWithText(AppButton, 'Save activity');
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(submitted, isNotNull);
        expect(submitted!.isPublic, isTrue);
        expect(submitted!.duration, 1.5);
        expect(submitted!.distanceKm, closeTo(0.25, 0.01));
      },
    );

    testWidgets(
      'blocks duplicate taps while saving and shows readable error SnackBar on failure allowing retry',
      (tester) async {
        Completer<Activity> completer = Completer<Activity>();
        final fakeService = _FakeActivityService((activity) {
          return completer.future;
        });

        await tester.pumpWidget(
          MaterialApp(home: ActivityRecordScreen(activityService: fakeService)),
        );

        await tester.tap(find.text('Start activity'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 5));
        await tester.tap(find.text('Pause'));
        await tester.pump();
        await tester.tap(find.text('Finish'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey<String>('workout_title_field')),
          'Evening Campus Jog',
        );
        await tester.enterText(
          find.byKey(const ValueKey<String>('workout_notes_field')),
          'Keep me on error',
        );

        final saveButtonFinder = find.byType(AppButton).first;
        await tester.ensureVisible(saveButtonFinder);
        await tester.tap(saveButtonFinder);
        await tester.pump();

        expect(fakeService.createCalls, 1);
        expect(tester.widget<AppButton>(saveButtonFinder).isLoading, isTrue);

        // Duplicate tap while request is in flight must be ignored.
        await tester.tap(saveButtonFinder);
        await tester.pump();
        expect(fakeService.createCalls, 1);

        completer.completeError(Exception('500 internal stack trace'));
        await tester.pumpAndSettle();

        expect(
          find.text('Could not save activity. Please try again.'),
          findsOneWidget,
        );
        expect(find.textContaining('500'), findsNothing);
        expect(find.textContaining('stack trace'), findsNothing);
        expect(find.byType(ActivityRecordScreen), findsOneWidget);
        expect(tester.widget<AppButton>(saveButtonFinder).isLoading, isFalse);

        // Recorded title, notes and metrics are preserved for retry.
        expect(find.text('Evening Campus Jog'), findsOneWidget);
        expect(find.text('Keep me on error'), findsOneWidget);
        expect(find.text('00:05'), findsOneWidget);

        // Retry succeeds cleanly.
        completer = Completer<Activity>();
        await tester.tap(saveButtonFinder);
        await tester.pump();
        expect(fakeService.createCalls, 2);

        completer.complete(
          Activity(
            id: 999,
            title: 'Evening Campus Jog',
            type: 'run',
            userId: 1,
            isPublic: false,
            createdAt: DateTime.now(),
          ),
        );
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Discard workout on summary opens confirmation dialog and discards without saving when confirmed',
      (tester) async {
        final fakeService = _FakeActivityService((activity) async => activity);

        await tester.pumpWidget(
          MaterialApp(
            initialRoute: '/',
            routes: {
              '/': (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<bool>(
                        builder: (_) =>
                            ActivityRecordScreen(activityService: fakeService),
                      ),
                    ),
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
        await tester.pump(const Duration(seconds: 4));
        await tester.tap(find.text('Pause'));
        await tester.pump();
        await tester.tap(find.text('Finish'));
        await tester.pumpAndSettle();

        final discardBtn = find.widgetWithText(AppButton, 'Discard workout');
        await tester.ensureVisible(discardBtn);
        await tester.tap(discardBtn);
        await tester.pumpAndSettle();

        expect(find.text('Discard workout?'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.byType(ActivityRecordScreen), findsOneWidget);
        expect(find.text('Save activity'), findsOneWidget);

        await tester.ensureVisible(discardBtn);
        await tester.tap(discardBtn);
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Discard'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ActivityRecordScreen), findsNothing);
        expect(fakeService.createCalls, 0);
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

      await tester.tap(find.text('Start activity'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text('Pause'));
      await tester.pump();
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();

      expect(find.text('Save activity'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
