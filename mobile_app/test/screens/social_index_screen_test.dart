import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/screens/app/social/index.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/auth_service.dart';

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await AuthService().enterDemoMode();
  });

  tearDown(() async {
    await ApiService().clearToken();
    ApiService.mockMode = false;
  });

  Future<void> openFindPeople(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: const SocialIndexScreen(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find people'));
    await tester.pumpAndSettle();
  }

  Future<void> typeQuery(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the hint until 2 letters are typed', (tester) async {
    await openFindPeople(tester);
    expect(find.text('Type at least 2 letters of a username.'), findsOneWidget);

    await typeQuery(tester, 'c');
    expect(find.text('Type at least 2 letters of a username.'), findsOneWidget);
    expect(find.text('Camille.B'), findsNothing);
  });

  testWidgets('lists matching members and an empty state', (tester) async {
    await openFindPeople(tester);

    await typeQuery(tester, 'ca');
    expect(find.text('Camille.B'), findsOneWidget);
    expect(find.text('Follow'), findsOneWidget);

    await typeQuery(tester, 'zz');
    expect(find.text('No members match "zz"'), findsOneWidget);
  });

  testWidgets('waits for a pause before searching', (tester) async {
    await openFindPeople(tester);

    await tester.enterText(find.byType(TextField), 'ca');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Camille.B'), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Camille.B'), findsOneWidget);
  });

  testWidgets('following from the results updates the button and the '
      'Following tab', (tester) async {
    await openFindPeople(tester);
    await typeQuery(tester, 'marc');

    await tester.tap(find.text('Follow'));
    await tester.pumpAndSettle();
    expect(find.text('Unfollow'), findsOneWidget);

    await tester.tap(find.text('Following'));
    await tester.pumpAndSettle();
    expect(find.text('Marc.V'), findsOneWidget);
  });

  testWidgets('shows an error with retry when the search fails', (
    tester,
  ) async {
    await openFindPeople(tester);
    // Without the mock, the test HTTP client answers 400 to every request.
    ApiService.mockMode = false;

    await typeQuery(tester, 'ca');
    expect(find.text('Search is unavailable right now.'), findsOneWidget);

    ApiService.mockMode = true;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Camille.B'), findsOneWidget);
  });
}
