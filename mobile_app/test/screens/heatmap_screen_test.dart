import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/heatmap.dart';
import 'package:mobile_app/screens/app/heatmap/index.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/widgets/error_state.dart';
import 'package:mobile_app/widgets/heatmap_view.dart';
import 'package:mobile_app/widgets/loading_state.dart';

void main() {
  setUp(() => ApiService.mockMode = true);
  tearDown(() => ApiService.mockMode = false);

  testWidgets(
    'loading then empty explains missing GPS without repeated requests',
    (tester) async {
      final result = Completer<HeatmapData?>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: HeatmapScreen(
            loadHeatmap: () {
              calls++;
              return result.future;
            },
          ),
        ),
      );
      expect(find.byType(LoadingState), findsOneWidget);
      result.complete(null);
      await tester.pumpAndSettle();
      expect(find.text('No GPS routes yet'), findsOneWidget);
      expect(calls, 1);
    },
  );

  testWidgets('error hides raw details and retry renders the heatmap', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HeatmapScreen(
          loadHeatmap: () {
            if (calls++ == 0) {
              return Future.error(Exception('private GPS details'));
            }
            return ActivityService().getHeatmap();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.textContaining('private GPS details'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(HeatmapView), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('leaving during loading does not update a disposed screen', (
    tester,
  ) async {
    final result = Completer<HeatmapData?>();
    await tester.pumpWidget(
      MaterialApp(home: HeatmapScreen(loadHeatmap: () => result.future)),
    );
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    result.complete(null);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
