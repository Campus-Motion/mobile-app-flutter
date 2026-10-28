import 'package:flutter/material.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/widgets/app_card.dart';

/// Reusable user list tile displaying an avatar, username, role / ID, and an optional trailing widget.
class UserListTile extends StatelessWidget {
  final User user;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? subtitle;

  const UserListTile({
    super.key,
    required this.user,
    this.trailing,
    this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final formattedRole = user.role.isNotEmpty
        ? user.role[0].toUpperCase() + user.role.substring(1)
        : 'Student';

    final displaySubtitle = subtitle ?? '$formattedRole • ID: ${user.id}';

    final ImageProvider avatarImage =
        (user.photoUrl != null && user.photoUrl!.isNotEmpty)
        ? NetworkImage(user.fullPhotoUrl!)
        : const AssetImage('assets/images/splash-icon.png') as ImageProvider;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      borderRadius: 16.0,
      border: Border.all(color: AppColors.divider),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: avatarImage,
            onBackgroundImageError: (_, _) {},
            radius: 24,
            backgroundColor: AppColors.surfaceLight,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  displaySubtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
