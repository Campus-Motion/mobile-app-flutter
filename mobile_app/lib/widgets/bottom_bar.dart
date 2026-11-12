import 'package:flutter/material.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/constants/colors.dart';

class CampusMotionBottomBar extends StatelessWidget {
  final int currentIndex;

  const CampusMotionBottomBar({super.key, required this.currentIndex});

  void _handleTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    Navigator.pushReplacementNamed(context, AppRoutes.tabRoute(index));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10)],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        // Ensures it doesn't overlap with iPhone "home bar"
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, 0, Icons.home_rounded, "Home"),
            _buildNavItem(context, 1, Icons.sports_soccer_rounded, "Sport"),
            _buildNavItem(context, 2, Icons.supervisor_account, "Social"),
            _buildNavItem(context, 3, Icons.person_rounded, "Profile"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final bool isActive = currentIndex == index;
    final Color color = isActive ? AppColors.primary : AppColors.textMuted;

    return GestureDetector(
      onTap: () => _handleTap(context, index),
      behavior: HitTestBehavior.opaque, // Makes the whole area clickable
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
