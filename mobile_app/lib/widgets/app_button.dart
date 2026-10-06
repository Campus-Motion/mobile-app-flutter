import 'package:flutter/material.dart';
import 'package:mobile_app/constants/colors.dart';

enum AppButtonVariant { primary, secondary, danger, outline }

/// Reusable button adhering to Campus Motion design tokens with loading state support.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? icon;
  final double height;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.height = 50.0,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = AppColors.primary;
        foregroundColor = Colors.white;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = AppColors.surfaceLight;
        foregroundColor = AppColors.textPrimary;
        break;
      case AppButtonVariant.danger:
        backgroundColor = AppColors.error;
        foregroundColor = Colors.white;
        break;
      case AppButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.primary;
        borderSide = const BorderSide(color: AppColors.primary, width: 1.5);
        break;
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: foregroundColor,
        ),
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: foregroundColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: foregroundColor,
            ),
          ),
        ],
      );
    } else {
      content = Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: foregroundColor,
        ),
      );
    }

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          side: borderSide,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.6),
        ),
        child: content,
      ),
    );
  }
}
