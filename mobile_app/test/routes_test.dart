import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/screens/app/activity/details.dart';
import 'package:mobile_app/screens/app/activity/index.dart';
import 'package:mobile_app/screens/app/activity/record.dart';
import 'package:mobile_app/screens/app/events/details.dart';
import 'package:mobile_app/screens/app/heatmap/index.dart';
import 'package:mobile_app/screens/app/home/index.dart';
import 'package:mobile_app/screens/app/profile/edit.dart';
import 'package:mobile_app/screens/app/profile/index.dart';
import 'package:mobile_app/screens/app/profile/settings.dart';
import 'package:mobile_app/screens/app/social/index.dart';
import 'package:mobile_app/screens/app/social/user_profile.dart';
import 'package:mobile_app/screens/auth/sign_in.dart';
import 'package:mobile_app/screens/auth/sign_up.dart';
import 'package:mobile_app/screens/auth/welcome.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/widgets/master_container.dart';

void main() {
  setUp(() async {
    ApiService.mockMode = true;
    await AuthService().enterDemoMode();
  });

  tearDown(() {
    AppRoutes.clearPendingRoute();
    ApiService.mockMode = false;
  });

  group('AppRoutes', () {
    final routeExpectations = <String, Type>{
      AppRoutes.login: WelcomeScreen,
      AppRoutes.signup: SignUpScreen,
      AppRoutes.signin: SignInScreen,
      AppRoutes.dashboard: HomeIndexScreen,
      AppRoutes.trail: ActivityIndexScreen,
      AppRoutes.recordActivity: ActivityRecordScreen,
      AppRoutes.social: SocialIndexScreen,
      AppRoutes.profile: ProfileIndexScreen,
      AppRoutes.userProfile: UserProfileScreen,
      AppRoutes.editProfile: ProfileEditScreen,
      AppRoutes.settings: ProfileSettingsScreen,
      AppRoutes.eventDetails: EventDetailsScreen,
      AppRoutes.activityDetails: ActivityDetailsScreen,
      AppRoutes.heatmaps: HeatmapScreen,
    };

    test('all route constants start with /', () {
      for (final route in routeExpectations.keys) {
        expect(
          route.startsWith('/'),
          isTrue,
          reason: 'Expected route "$route" to start with "/"',
        );
      }
    });

    test(
      'every AppRoutes constant resolves to its screen and not the fallback',
      () {
        final context = _DummyBuildContext();
        for (final entry in routeExpectations.entries) {
          final route = AppRoutes.generateRoute(
            RouteSettings(
              name: entry.key,
              arguments:
                  (entry.key == AppRoutes.eventDetails ||
                      entry.key == AppRoutes.activityDetails)
                  ? 101
                  : null,
            ),
          );

          expect(route, isA<MaterialPageRoute<dynamic>>());
          final pageRoute = route as MaterialPageRoute<dynamic>;
          final builtWidget = pageRoute.builder(context);

          expect(builtWidget.runtimeType, entry.value);
        }
      },
    );

    testWidgets(
      'unknown route fallback uses MasterContainer and navigates back to dashboard',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            initialRoute: '/unknown-route',
            onGenerateRoute: AppRoutes.generateRoute,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MasterContainer), findsOneWidget);
        expect(
          find.text('No route defined for /unknown-route'),
          findsOneWidget,
        );
        expect(find.text('Back to dashboard'), findsOneWidget);

        await tester.tap(find.text('Back to dashboard'));
        await tester.pumpAndSettle();

        expect(find.byType(HomeIndexScreen), findsOneWidget);
      },
    );

    test('parses /users/<id> routes and builds shareable URLs', () {
      expect(AppRoutes.parseUserProfileId('/users/2'), 2);
      expect(AppRoutes.parseUserProfileId('/users/2/'), 2);
      expect(AppRoutes.parseUserProfileId('/users/2?ref=share'), 2);
      expect(AppRoutes.parseUserProfileId('/users/abc'), isNull);
      expect(AppRoutes.parseUserProfileId('/users/0'), isNull);
      expect(AppRoutes.userProfileUrl(2), '${AppRoutes.appBaseUrl}/users/2');
    });

    test(
      'resolves /users/<id> for another user, own user, and signed out',
      () async {
        final context = _DummyBuildContext();

        // Another member (user 2) while signed in as user 1
        final otherRoute =
            AppRoutes.generateRoute(const RouteSettings(name: '/users/2'))
                as MaterialPageRoute<dynamic>;
        final otherWidget = otherRoute.builder(context);
        expect(otherWidget, isA<UserProfileScreen>());
        expect((otherWidget as UserProfileScreen).userId, 2);

        // Own link (user 1) redirects to ProfileIndexScreen
        final ownRoute =
            AppRoutes.generateRoute(const RouteSettings(name: '/users/1'))
                as MaterialPageRoute<dynamic>;
        expect(ownRoute.builder(context), isA<ProfileIndexScreen>());

        // Signed out redirects to SignInScreen and saves pending route
        await AuthService().logout();
        final signedOutRoute =
            AppRoutes.generateRoute(const RouteSettings(name: '/users/2'))
                as MaterialPageRoute<dynamic>;
        expect(signedOutRoute.builder(context), isA<SignInScreen>());
        expect(AppRoutes.pendingRoute, '/users/2');
        expect(AppRoutes.consumePostAuthRoute(), '/users/2');
        expect(AppRoutes.consumePostAuthRoute(), AppRoutes.dashboard);
      },
    );
  });
}

class _DummyBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
