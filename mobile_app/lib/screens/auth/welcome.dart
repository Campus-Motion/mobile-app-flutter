import 'package:flutter/material.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/app_button.dart';
import 'package:mobile_app/services/auth_service.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MasterContainer(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
      scrollable: false,
      children: [
        const SizedBox(
          height: 16,
        ),
        const Image(
          image: AssetImage('assets/images/logo_peach.png'),
        ),
        const Spacer(
          flex: 1,
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
          style: TextButton.styleFrom(
            minimumSize: const Size(300, 50),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white, // Setting text color to white for better contrast
          ),
          child: const Text('Sign Up'),
        ),
        const SizedBox(
          height: 16,
        ),
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.signin),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(300, 50),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
          ),
          child: const Text('Sign In'),
        ),
        const SizedBox(
          height: 16,
        ),
        AppButton(
          text: 'Demo Mode (Offline Bypass)',
          variant: AppButtonVariant.secondary,
          icon: Icons.bolt,
          width: 300,
          onPressed: () async {
            await AuthService().enterDemoMode();
            if (!context.mounted) return;
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
