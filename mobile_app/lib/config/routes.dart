import 'package:flutter/material.dart';
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
import 'package:mobile_app/widgets/error_state.dart';
import 'package:mobile_app/widgets/master_container.dart';

class AppRoutes {
  // Route Names (Think of these as your constant IDs)
  static const String login = '/';
  static const String signup = '/signup';
  static const String signin = '/signin';
  static const String dashboard = '/dashboard';
  static const String trail = '/trail';
  static const String social = '/social';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/profile/settings';
  static const String eventDetails = '/events/details';

  static String tabRoute(int index) {
    switch (index) {
      case 0:
        return dashboard;
      case 1:
        return trail;
      case 2:
        return social;
      case 3:
        return profile;
      case _:
        return dashboard;
    }
  }

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case signin:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const HomeIndexScreen());
      case trail:
        return MaterialPageRoute(builder: (_) => const ActivityIndexScreen());
      case social:
        return MaterialPageRoute(builder: (_) => const SocialIndexScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileIndexScreen());
      case editProfile:
        return MaterialPageRoute(builder: (_) => const ProfileEditScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const ProfileSettingsScreen());
      case eventDetails:
        final eventId = routeSettings.arguments is int
            ? routeSettings.arguments as int
            : null;
        return MaterialPageRoute(
          builder: (_) => EventDetailsScreen(eventId: eventId),
          settings: routeSettings,
        );
      default:
        return MaterialPageRoute(
          builder: (context) => MasterContainer(
            children: [
              ErrorState(
                message: 'No route defined for ${routeSettings.name}',
                retryLabel: 'Back to dashboard',
                onRetry: () =>
                    Navigator.pushReplacementNamed(context, dashboard),
              ),
            ],
          ),
        );
    }
  }
}
