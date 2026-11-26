import 'package:flutter/material.dart';
import 'package:mobile_app/models/activity.dart';
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
import 'package:mobile_app/widgets/error_state.dart';
import 'package:mobile_app/widgets/master_container.dart';

class AppRoutes {
  /// Public web origin used when generating shareable profile links.
  static const String appBaseUrl = 'https://campusmotion.ch';

  // Route Names (Think of these as your constant IDs)
  static const String login = '/';
  static const String signup = '/signup';
  static const String signin = '/signin';
  static const String dashboard = '/dashboard';
  static const String trail = '/trail';
  static const String heatmap = '/heatmap';
  static const String recordActivity = '/activity/record';
  static const String social = '/social';
  static const String profile = '/profile';
  static const String userProfile = '/users';
  static const String editProfile = '/profile/edit';
  static const String settings = '/profile/settings';
  static const String eventDetails = '/events/details';
  static const String activityDetails = '/activities/details';
  static const String heatmaps = '/heatmaps';

  static String? _pendingRoute;

  static String? get pendingRoute => _pendingRoute;

  static void setPendingRoute(String? route) {
    _pendingRoute = route;
  }

  static void clearPendingRoute() {
    _pendingRoute = null;
  }

  /// Returns and clears the route saved while signed out, or [dashboard] if none.
  static String consumePostAuthRoute() {
    final target = _pendingRoute;
    _pendingRoute = null;
    return target ?? dashboard;
  }

  /// Builds the app route path for a member profile (`/users/<id>`).
  static String userProfilePath(int userId) => '$userProfile/$userId';

  /// Builds the full shareable URL for a member profile.
  static String userProfileUrl(int userId) =>
      '$appBaseUrl${userProfilePath(userId)}';

  /// Returns true when [routeName] targets `/users` or `/users/<segment>`.
  static bool isUserProfileRoute(String? routeName) {
    if (routeName == null || routeName.isEmpty) return false;
    final uri = Uri.tryParse(routeName);
    if (uri == null) return false;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return segments.isNotEmpty &&
        segments.first == 'users' &&
        segments.length <= 2;
  }

  /// Extracts a positive member ID from `/users/<id>`, or null if invalid.
  static int? parseUserProfileId(String? routeName) {
    if (routeName == null || routeName.isEmpty) return null;
    final uri = Uri.tryParse(routeName);
    if (uri == null) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length != 2 || segments.first != 'users') return null;
    final parsed = int.tryParse(segments[1]);
    return (parsed != null && parsed > 0) ? parsed : null;
  }

  static List<Route<dynamic>> generateInitialRoutes(String initialRouteName) {
    return [generateRoute(RouteSettings(name: initialRouteName))];
  }

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
    final routeName = routeSettings.name;
    if (isUserProfileRoute(routeName)) {
      final isSignedIn =
          ApiService().isAuthenticated || AuthService().currentUser != null;
      final pathUserId = parseUserProfileId(routeName);
      final argUserId = routeSettings.arguments is int
          ? routeSettings.arguments as int
          : null;
      final userId = pathUserId ?? argUserId;

      if (!isSignedIn) {
        final targetRoute = userId != null
            ? userProfilePath(userId)
            : (routeName ?? userProfile);
        setPendingRoute(targetRoute);
        return MaterialPageRoute(
          builder: (_) => const SignInScreen(),
          settings: const RouteSettings(name: signin),
        );
      }

      if (userId != null && AuthService().currentUser?.id == userId) {
        return MaterialPageRoute(
          builder: (_) => const ProfileIndexScreen(),
          settings: const RouteSettings(name: profile),
        );
      }

      return MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: userId),
        settings: routeSettings,
      );
    }

    switch (routeName) {
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
      case heatmap:
        return MaterialPageRoute(builder: (_) => const HeatmapScreen());
      case recordActivity:
        return MaterialPageRoute(builder: (_) => const ActivityRecordScreen());
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
      case activityDetails:
        final args = routeSettings.arguments;
        final activityId = args is int
            ? args
            : (args is Activity ? args.id : null);
        final initialActivity = args is Activity ? args : null;
        return MaterialPageRoute(
          builder: (_) => ActivityDetailsScreen(
            activityId: activityId,
            initialActivity: initialActivity,
          ),
          settings: routeSettings,
        );
      case heatmaps:
        return MaterialPageRoute(
          builder: (_) => const HeatmapScreen(),
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
