import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/screens/app/heatmap/index.dart';
import 'package:mobile_app/screens/app/profile/index.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/mock_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService.mockMode = true;
    MockDataService().resetMockActivities();
  });

  tearDown(() {
    ApiService.mockMode = false;
  });

  testWidgets(
    'ProfileIndexScreen replaces legacy stat row with My Heatmaps & Statistics button and navigates on tap',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.profile,
          routes: {
            AppRoutes.profile: (_) => const ProfileIndexScreen(),
            AppRoutes.heatmaps: (_) =>
                HeatmapScreen(loadTracks: (_) async => const []),
            AppRoutes.dashboard: (_) => const Scaffold(body: Text('Dashboard')),
            AppRoutes.trail: (_) => const Scaffold(body: Text('Sport')),
            AppRoutes.social: (_) => const Scaffold(body: Text('Social')),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Legacy profile statistics row is gone
      expect(find.text('Active Time'), findsNothing);

      // New button is displayed in its place
      expect(find.text('My Heatmaps & Statistics'), findsOneWidget);

      await tester.tap(find.text('My Heatmaps & Statistics'));
      await tester.pumpAndSettle();

      expect(find.byType(HeatmapScreen), findsOneWidget);
    },
  );
}
