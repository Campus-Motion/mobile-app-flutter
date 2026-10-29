import 'package:flutter/material.dart';

import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/widgets/app_button.dart';

/// Icon + message + optional retry button for failed async loads.
///
/// The retry button is rendered only when [onRetry] is provided.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.retryLabel = 'Retry',
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              AppButton(text: retryLabel, onPressed: onRetry, width: 160),
            ],
          ],
        ),
      ),
    );
  }
}
