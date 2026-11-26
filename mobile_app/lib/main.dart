import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/services/auth_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

String detectRequestedRoute() {
  final platformRoute =
      WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  if (platformRoute.isNotEmpty && platformRoute != Navigator.defaultRouteName) {
    return platformRoute;
  }
  if (kIsWeb && Uri.base.path.isNotEmpty && Uri.base.path != '/') {
    return Uri.base.path;
  }
  return AppRoutes.login;
}

Future<String> resolveInitialRoute({String? requestedRoute}) async {
  final restored = await AuthService().restoreSession();
  if (AppRoutes.isUserProfileRoute(requestedRoute) && requestedRoute != null) {
    if (restored) {
      AppRoutes.clearPendingRoute();
      final userId = AppRoutes.parseUserProfileId(requestedRoute);
      if (userId != null && AuthService().currentUser?.id == userId) {
        return AppRoutes.profile;
      }
      return requestedRoute;
    }
    AppRoutes.setPendingRoute(requestedRoute);
    return AppRoutes.signin;
  }

  AppRoutes.clearPendingRoute();
  return restored ? AppRoutes.dashboard : AppRoutes.login;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    HttpOverrides.global = MyHttpOverrides();
  }
  final requestedRoute = detectRequestedRoute();
  final initialRoute = await resolveInitialRoute(
    requestedRoute: requestedRoute,
  );
  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, this.initialRoute = AppRoutes.login});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusMotion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      //Routes
      initialRoute: initialRoute,
      onGenerateInitialRoutes: (String initialRouteName) {
        final effectiveRoute = initialRoute != AppRoutes.login
            ? initialRoute
            : initialRouteName;
        return AppRoutes.generateInitialRoutes(effectiveRoute);
      },
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
