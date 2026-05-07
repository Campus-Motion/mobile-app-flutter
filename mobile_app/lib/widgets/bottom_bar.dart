import 'package:flutter/material.dart';

class CampusMotionBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(BuildContext, int) onTap; // Callback for navigation
  final BuildContext context;

  const CampusMotionBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.context
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea( // Ensures it doesn't overlap with iPhone "home bar"
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, "Home"),
            _buildNavItem(1, Icons.sports_soccer_rounded, "Teams"),
            _buildNavItem(2, Icons.supervisor_account, "Social"),
            _buildNavItem(3, Icons.person_rounded, "Profile"),
          ],
        ),
      ),
    );
  }
  

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isActive = currentIndex == index;
    final Color color = isActive ? Colors.blue : Colors.grey;

    return GestureDetector(
      onTap: () => onTap(context, index),
      behavior: HitTestBehavior.opaque, // Makes the whole area clickable
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }
}