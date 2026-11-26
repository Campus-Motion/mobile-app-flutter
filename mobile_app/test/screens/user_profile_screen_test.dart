import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/main.dart';
import 'package:mobile_app/screens/app/profile/index.dart';
import 'package:mobile_app/screens/app/social/index.dart';
import 'package:mobile_app/screens/app/social/user_profile.dart';
import 'package:mobile_app/screens/auth/sign_in.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/mock_data_service.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/widgets/master_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    ApiService.mockMode = true;
    MockDataService().resetMockSocial();
    AppRoutes.clearPendingRoute();
    await AuthService().enterDemoMode();
  });

  tearDown(() async {
    AppRoutes.clearPendingRoute();
    await AuthService().logout();
    ApiService.mockMode = false;
  });

  group('UserProfileScreen', () {
    testWidgets(
      'displays public member profile only and toggles follow/unfollow',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            initialRoute: '/users/2',
            onGenerateInitialRoutes: AppRoutes.generateInitialRoutes,
            onGenerateRoute: AppRoutes.generateRoute,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MasterContainer), findsOneWidget);
        expect(find.byType(UserProfileScreen), findsOneWidget);
        expect(find.text('Camille.B'), findsOneWidget);
        expect(find.text('Student • Campus Motion'), findsOneWidget);
        expect(find.text('Follow'), findsOneWidget);

        // Public fields only: no email or health data displayed
        expect(find.textContaining('@'), findsNothing);
        expect(find.textContaining('kg'), findsNothing);
        expect(find.textContaining('cm'), findsNothing);

        final fetched = await UserService().getUser(2);
        expect(fetched.email, isNull);

        // Toggle Follow -> Unfollow
        await tester.tap(find.text('Follow'));
        await tester.pumpAndSettle();
        expect(find.text('Unfollow'), findsOneWidget);

        // Toggle Unfollow -> Follow
        await tester.tap(find.text('Unfollow'));
        await tester.pumpAndSettle();
        expect(find.text('Follow'), findsOneWidget);
      },
    );

    testWidgets('shows not-found message for an unknown user ID', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          initialRoute: '/users/999',
          onGenerateInitialRoutes: AppRoutes.generateInitialRoutes,
          onGenerateRoute: AppRoutes.generateRoute,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UserProfileScreen), findsOneWidget);
      expect(find.text('Member not found'), findsOneWidget);
      expect(find.text('Go back'), findsOneWidget);
    });

    testWidgets('shows not-found message for an invalid user path', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          initialRoute: '/users/not-a-number',
          onGenerateInitialRoutes: AppRoutes.generateInitialRoutes,
          onGenerateRoute: AppRoutes.generateRoute,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UserProfileScreen), findsOneWidget);
      expect(find.text('Member not found'), findsOneWidget);
    });

    testWidgets('redirects to own profile when opening own user ID', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const UserProfileScreen(userId: 1),
          onGenerateRoute: AppRoutes.generateRoute,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfileIndexScreen), findsOneWidget);
    });

    testWidgets(
      'opening a profile link while signed out goes to sign-in then to the profile',
      (tester) async {
        await AuthService().logout();

        final resolved = await resolveInitialRoute(requestedRoute: '/users/2');
        expect(resolved, AppRoutes.signin);
        expect(AppRoutes.pendingRoute, '/users/2');

        await tester.pumpWidget(MyApp(initialRoute: resolved));
        await tester.pumpAndSettle();

        expect(find.byType(SignInScreen), findsOneWidget);

        await tester.enterText(find.byType(TextField).at(0), 'robin@epfl.ch');
        await tester.enterText(find.byType(TextField).at(1), 'password123');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(find.byType(UserProfileScreen), findsOneWidget);
        expect(find.text('Camille.B'), findsOneWidget);
        expect(AppRoutes.pendingRoute, isNull);
      },
    );
  });

  group('SocialIndexScreen member profile navigation', () {
    testWidgets(
      'tapping members in Following, Followers and Find User opens UserProfileScreen',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SocialIndexScreen(),
            onGenerateRoute: AppRoutes.generateRoute,
          ),
        );
        await tester.pumpAndSettle();

        // Following tab -> tap Sarah.L (id 4)
        expect(find.text('Sarah.L'), findsOneWidget);
        await tester.tap(find.text('Sarah.L'));
        await tester.pumpAndSettle();
        expect(find.byType(UserProfileScreen), findsOneWidget);
        expect(find.text('Sarah.L'), findsOneWidget);
        expect(find.text('Unfollow'), findsOneWidget);

        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();

        // Followers tab -> tap Camille.B (id 2)
        await tester.tap(find.text('Followers'));
        await tester.pumpAndSettle();
        expect(find.text('Camille.B'), findsOneWidget);
        await tester.tap(find.text('Camille.B'));
        await tester.pumpAndSettle();
        expect(find.byType(UserProfileScreen), findsOneWidget);
        expect(find.text('Camille.B'), findsOneWidget);

        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();

        // Find User tab -> search ID 3 (Marc.V) and tap the result tile
        await tester.tap(find.text('Find User'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '3');
        await tester.tap(find.text('Search'));
        await tester.pumpAndSettle();
        expect(find.text('Marc.V'), findsOneWidget);

        await tester.tap(find.text('Marc.V'));
        await tester.pumpAndSettle();
        expect(find.byType(UserProfileScreen), findsOneWidget);
        expect(find.text('Marc.V'), findsOneWidget);
      },
    );
  });
}
