import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/loop_route.dart';
import 'package:mobile_app/widgets/activity_card.dart';
import 'package:mobile_app/widgets/app_button.dart';
import 'package:mobile_app/widgets/app_card.dart';
import 'package:mobile_app/widgets/loop_route_card.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: child,
    ),
  ),
);

void main() {
  group('LoopRouteCard', () {
    testWidgets('toggles between Free workout and Distance loop modes', (
      tester,
    ) async {
      bool? latestMode;

      await tester.pumpWidget(
        _wrap(
          LoopRouteCard(
            isLoopMode: false,
            targetDistanceKm: 5.0,
            onModeChanged: (val) => latestMode = val,
            onDistanceChanged: (_) {},
            onGenerateLoop: () {},
          ),
        ),
      );

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.text('Free workout'), findsOneWidget);
      expect(find.text('Distance loop'), findsOneWidget);
      expect(find.byType(Slider), findsNothing);
      expect(find.text('Generate loop'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey<String>('mode_distance_loop')),
      );
      await tester.pump();
      expect(latestMode, isTrue);

      await tester.tap(find.byKey(const ValueKey<String>('mode_free_workout')));
      await tester.pump();
      expect(latestMode, isFalse);
    });

    testWidgets(
      'shows distance slider and outline Generate loop button in Distance loop mode',
      (tester) async {
        double? changedDistance;
        var generateCalls = 0;

        await tester.pumpWidget(
          _wrap(
            LoopRouteCard(
              isLoopMode: true,
              targetDistanceKm: 8.5,
              onModeChanged: (_) {},
              onDistanceChanged: (val) => changedDistance = val,
              onGenerateLoop: () => generateCalls++,
            ),
          ),
        );

        expect(find.text('Target distance'), findsOneWidget);
        expect(find.text('8.5 km'), findsOneWidget);

        final sliderFinder = find.byKey(
          const ValueKey<String>('loop_distance_slider'),
        );
        expect(sliderFinder, findsOneWidget);
        final slider = tester.widget<Slider>(sliderFinder);
        expect(slider.min, 1.0);
        expect(slider.max, 30.0);
        expect(slider.value, 8.5);

        await tester.drag(sliderFinder, const Offset(80, 0));
        await tester.pump();
        expect(changedDistance, isNotNull);
        expect(changedDistance, greaterThan(8.5));

        final generateFinder = find.widgetWithText(AppButton, 'Generate loop');
        expect(generateFinder, findsOneWidget);
        expect(
          tester.widget<AppButton>(generateFinder).variant,
          AppButtonVariant.outline,
        );

        await tester.tap(generateFinder);
        await tester.pump();
        expect(generateCalls, 1);
      },
    );

    testWidgets(
      'displays loop summary preview with distance, duration and preview notice',
      (tester) async {
        const preview = LoopRoute(
          targetDistanceKm: 10.0,
          estimatedDistanceKm: 10.0,
          estimatedDuration: Duration(minutes: 30),
          sportType: 'cycle',
          isPreview: true,
        );

        await tester.pumpWidget(
          _wrap(
            LoopRouteCard(
              isLoopMode: true,
              targetDistanceKm: 10.0,
              generatedLoop: preview,
              onModeChanged: (_) {},
              onDistanceChanged: (_) {},
              onGenerateLoop: () {},
            ),
          ),
        );

        expect(find.text('Loop summary'), findsOneWidget);
        expect(find.text('Preview mode'), findsOneWidget);
        expect(find.text('10.0'), findsOneWidget);
        expect(find.text('km'), findsOneWidget);
        expect(find.text('30m'), findsOneWidget);
        expect(
          find.byIcon(ActivityCard.getActivityIcon('cycle')),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'Live loop routing from your current position is in preview mode.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Cycle'), findsOneWidget);
      },
    );

    testWidgets('shows loading state and inline error message', (tester) async {
      var modeChanged = false;
      var generateCalls = 0;

      await tester.pumpWidget(
        _wrap(
          LoopRouteCard(
            isLoopMode: true,
            targetDistanceKm: 5.0,
            isGenerating: true,
            errorMessage: 'Could not generate loop preview. Please try again.',
            onModeChanged: (_) => modeChanged = true,
            onDistanceChanged: (_) {},
            onGenerateLoop: () => generateCalls++,
          ),
        ),
      );

      expect(
        tester.widget<AppButton>(find.byType(AppButton)).isLoading,
        isTrue,
      );
      expect(
        find.text('Could not generate loop preview. Please try again.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey<String>('mode_free_workout')));
      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(modeChanged, isFalse);
      expect(generateCalls, 0);
    });

    testWidgets(
      'meets 48x48 tap targets and renders without overflow on a 320px wide screen',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const preview = LoopRoute(
          targetDistanceKm: 15.0,
          estimatedDistanceKm: 15.0,
          estimatedDuration: Duration(minutes: 90),
          sportType: 'run',
        );

        await tester.pumpWidget(
          _wrap(
            LoopRouteCard(
              isLoopMode: true,
              targetDistanceKm: 15.0,
              generatedLoop: preview,
              onModeChanged: (_) {},
              onDistanceChanged: (_) {},
              onGenerateLoop: () {},
            ),
          ),
        );

        expect(tester.takeException(), isNull);

        for (final finder in [
          find.byKey(const ValueKey<String>('mode_free_workout')),
          find.byKey(const ValueKey<String>('mode_distance_loop')),
          find.widgetWithText(AppButton, 'Generate loop'),
        ]) {
          final size = tester.getSize(finder);
          expect(size.width, greaterThanOrEqualTo(48.0));
          expect(size.height, greaterThanOrEqualTo(48.0));
        }
      },
    );
  });
}
