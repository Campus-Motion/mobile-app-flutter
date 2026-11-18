import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/widgets/app_button.dart';
import 'package:mobile_app/widgets/workout_control_bar.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(24), child: child),
  ),
);

void main() {
  group('WorkoutControlBar', () {
    testWidgets('idle state renders Start activity button and calls onStart', (
      tester,
    ) async {
      var started = false;

      await tester.pumpWidget(
        _wrap(
          WorkoutControlBar(
            status: WorkoutStatus.idle,
            onStart: () => started = true,
          ),
        ),
      );

      expect(find.byType(AppButton), findsOneWidget);
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.variant, AppButtonVariant.primary);
      expect(find.text('Start activity'), findsOneWidget);

      final size = tester.getSize(find.byType(AppButton));
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));

      await tester.tap(find.text('Start activity'));
      await tester.pump();
      expect(started, isTrue);
    });

    testWidgets('recording state renders Pause button and calls onPause', (
      tester,
    ) async {
      var paused = false;

      await tester.pumpWidget(
        _wrap(
          WorkoutControlBar(
            status: WorkoutStatus.recording,
            onPause: () => paused = true,
          ),
        ),
      );

      expect(find.byType(AppButton), findsOneWidget);
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.variant, AppButtonVariant.secondary);
      expect(find.text('Pause'), findsOneWidget);

      final size = tester.getSize(find.byType(AppButton));
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));

      await tester.tap(find.text('Pause'));
      await tester.pump();
      expect(paused, isTrue);
    });

    testWidgets(
      'paused state renders Resume, Finish and Discard buttons with callbacks',
      (tester) async {
        var resumed = false;
        var finished = false;
        var discarded = false;

        await tester.pumpWidget(
          _wrap(
            WorkoutControlBar(
              status: WorkoutStatus.paused,
              onResume: () => resumed = true,
              onFinish: () => finished = true,
              onDiscard: () => discarded = true,
            ),
          ),
        );

        final buttons = tester.widgetList<AppButton>(find.byType(AppButton));
        expect(buttons.length, 3);
        expect(
          buttons.map((b) => (b.text, b.variant)).toList(),
          equals([
            ('Resume', AppButtonVariant.outline),
            ('Finish', AppButtonVariant.primary),
            ('Discard', AppButtonVariant.danger),
          ]),
        );

        for (final finder in [
          find.widgetWithText(AppButton, 'Resume'),
          find.widgetWithText(AppButton, 'Finish'),
          find.widgetWithText(AppButton, 'Discard'),
        ]) {
          final size = tester.getSize(finder);
          expect(size.width, greaterThanOrEqualTo(48.0));
          expect(size.height, greaterThanOrEqualTo(48.0));
        }

        await tester.tap(find.text('Resume'));
        await tester.tap(find.text('Finish'));
        await tester.tap(find.text('Discard'));
        await tester.pump();

        expect(resumed, isTrue);
        expect(finished, isTrue);
        expect(discarded, isTrue);
      },
    );

    testWidgets('paused state renders without overflow on 320px wide screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          WorkoutControlBar(
            status: WorkoutStatus.paused,
            onResume: () {},
            onFinish: () {},
            onDiscard: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
