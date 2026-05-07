import 'package:flutter/material.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/widgets/master_container.dart';
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MasterContainer(
      padding: const EdgeInsets.all(50.0),
      scrollable: false,
      children: [
        const SizedBox(
          height: 16,
          ),
        const Image(
          image:AssetImage('assets/images/logo_bleu.png'),

        ),
        const Spacer(
          flex:1
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
          height: 20
        ),
        OutlinedButton(
          onPressed : () => Navigator.pushNamed(context, AppRoutes.signin),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(300, 50),
              backgroundColor:Colors.white,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary)
                ),
          child : const Text('Sign In')
        ),
        const SizedBox(height:100)
      ],
    );
  }
}
