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

Future<String> resolveInitialRoute() async {
  final restored = await AuthService().restoreSession();
  return restored ? AppRoutes.dashboard : AppRoutes.login;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    HttpOverrides.global = MyHttpOverrides();
  }
  final initialRoute = await resolveInitialRoute();
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
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
