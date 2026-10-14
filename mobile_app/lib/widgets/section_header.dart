import 'package:flutter/material.dart';
import 'package:mobile_app/constants/colors.dart';

/// Large bold section title used to separate content blocks on a screen
/// (e.g. "Upcoming Events", "Latest News" on the Home dashboard).
class SectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
