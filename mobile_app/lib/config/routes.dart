import 'package:flutter/material.dart';
import 'package:mobile_app/screens/app/activity/index.dart';
import 'package:mobile_app/screens/app/profile/edit.dart';
import 'package:mobile_app/screens/app/profile/index.dart';
import 'package:mobile_app/screens/app/profile/settings.dart';
import 'package:mobile_app/screens/app/social/index.dart';
import 'package:mobile_app/screens/auth/sign_in.dart';
import '../screens/auth/welcome.dart';
import '../screens/auth/sign_up.dart';
import '../screens/app/home/index.dart'; // Add import for Dashboard (HomeIndexScreen)

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
  static const String shareProfile = 'profile/share';
  static const String parameters = 'profile/parameters';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case signin :
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const HomeIndexScreen());
      case trail :
        return MaterialPageRoute(builder : (_) => const ActivityIndexScreen());
      case social :
        return MaterialPageRoute(builder : (_) => const SocialIndexScreen());
      case profile :
        return MaterialPageRoute(builder: (_) => const ProfileIndexScreen());
      case editProfile :
        return MaterialPageRoute(builder : (_) => const ProfileEditScreen());
      case shareProfile :
        return MaterialPageRoute(builder : (_) => const HomeIndexScreen()); //TODO : Change path
      case parameters : 
        return MaterialPageRoute(builder : (_) => const ProfileSettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}