import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/screens/app/activity/index.dart';
import 'package:mobile_app/screens/app/events/details.dart';
import 'package:mobile_app/screens/app/home/index.dart';
import 'package:mobile_app/screens/app/profile/edit.dart';
import 'package:mobile_app/screens/app/profile/index.dart';
import 'package:mobile_app/screens/app/profile/settings.dart';
import 'package:mobile_app/screens/app/social/index.dart';
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
    ApiService.mockMode = false;
  });

  group('AppRoutes', () {
    final routeExpectations = <String, Type>{
      AppRoutes.login: WelcomeScreen,
      AppRoutes.signup: SignUpScreen,
      AppRoutes.signin: SignInScreen,
      AppRoutes.dashboard: HomeIndexScreen,
      AppRoutes.trail: ActivityIndexScreen,
      AppRoutes.social: SocialIndexScreen,
      AppRoutes.profile: ProfileIndexScreen,
      AppRoutes.editProfile: ProfileEditScreen,
      AppRoutes.settings: ProfileSettingsScreen,
      AppRoutes.eventDetails: EventDetailsScreen,
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
              arguments: entry.key == AppRoutes.eventDetails ? 101 : null,
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
  });
}

class _DummyBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
