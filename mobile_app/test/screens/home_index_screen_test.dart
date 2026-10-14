import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/screens/app/home/index.dart';
import 'package:mobile_app/services/api_service.dart';

void main() {
  setUp(() {
    ApiService.mockMode = true;
  });

  tearDown(() {
    ApiService.mockMode = false;
  });

  testWidgets('HomeIndexScreen loads upcoming events and excludes past events after refresh', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: const HomeIndexScreen(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );

    await tester.pumpAndSettle();

    // Check that upcoming event is visible and past event is excluded on initial load
    expect(find.text('Sunset Lake Trail Run'), findsOneWidget);
    expect(find.text('Past Campus Welcome Run'), findsNothing);

    // Trigger pull-to-refresh
    final refreshIndicator = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
    await refreshIndicator.onRefresh();
    await tester.pumpAndSettle();

    // Check that after pull-to-refresh, past event is still excluded and upcoming event is shown
    expect(find.text('Sunset Lake Trail Run'), findsOneWidget);
    expect(find.text('Past Campus Welcome Run'), findsNothing);
  });
}
