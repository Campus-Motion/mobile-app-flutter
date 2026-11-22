import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/widgets/heatmap_view.dart';

void main() {
  testWidgets('heatmap supports zoom and remains usable on a narrow screen', (
    tester,
  ) async {
    ApiService.mockMode = true;
    addTearDown(() => ApiService.mockMode = false);
    final data = (await ActivityService().getHeatmap())!;
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: HeatmapView(heatmap: data)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.textContaining('1 activity'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
