import 'package:flutter/material.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/widgets/app_button.dart';
import 'package:mobile_app/widgets/app_card.dart';
import 'package:mobile_app/widgets/empty_state.dart';
import 'package:mobile_app/widgets/error_state.dart';
import 'package:mobile_app/widgets/loading_state.dart';
import 'package:mobile_app/widgets/master_container.dart';

/// Displays another member's public profile with a one-tap Follow / Unfollow
/// button. Opening the signed-in user's own ID redirects to [AppRoutes.profile].
class UserProfileScreen extends StatefulWidget {
  final int? userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  User? _user;
  bool _isFollowing = false;
  bool _isLoading = true;
  bool _isNotFound = false;
  bool _hasError = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final targetId = widget.userId;
    if (targetId == null || targetId <= 0) {
      setState(() {
        _isLoading = false;
        _isNotFound = true;
        _hasError = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isNotFound = false;
      _hasError = false;
    });

    try {
      final currentUser =
          _authService.currentUser ?? await _authService.getProfile();
      if (!mounted) return;

      if (currentUser != null && currentUser.id == targetId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, AppRoutes.profile);
        });
        return;
      }

      final followingFuture = currentUser != null
          ? _userService
                .getFollowing(currentUser.id)
                .catchError((_) => <User>[])
          : Future<List<User>>.value(<User>[]);

      final results = await Future.wait<Object>([
        _userService.getUser(targetId),
        followingFuture,
      ]);

      if (!mounted) return;

      final user = results[0] as User;
      final following = results[1] as List<User>;

      setState(() {
        _user = user;
        _isFollowing = following.any((u) => u.id == user.id);
        _isLoading = false;
        _isNotFound = false;
        _hasError = false;
      });
    } on UserNotFoundException {
      if (!mounted) return;
      setState(() {
        _user = null;
        _isLoading = false;
        _isNotFound = true;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _user = null;
        _isLoading = false;
        _isNotFound = false;
        _hasError = true;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final user = _user;
    if (user == null || _isFollowLoading) return;

    final wasFollowing = _isFollowing;
    setState(() {
      _isFollowLoading = true;
    });

    try {
      if (wasFollowing) {
        await _userService.unfollowUser(user.id);
      } else {
        await _userService.followUser(user.id);
      }

      if (!mounted) return;
      setState(() {
        _isFollowing = !wasFollowing;
        _isFollowLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFollowing
                ? 'Unfollowed ${user.username}'
                : 'Following ${user.username}',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFollowLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update follow status. Please try again.'),
        ),
      );
    }
  }

  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
  }

  String _formatRole(String role) {
    if (role.isEmpty) return 'Member';
    return role[0].toUpperCase() + role.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return MasterContainer(
      onRefresh: _loadProfile,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              tooltip: 'Back',
              onPressed: _handleBack,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Member profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_isLoading)
          const LoadingState(height: 240)
        else if (_isNotFound)
          Column(
            children: [
              const EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Member not found',
                subtitle:
                    'This profile link may be invalid or the member no longer exists.',
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Go back',
                variant: AppButtonVariant.outline,
                onPressed: _handleBack,
                width: 180,
              ),
            ],
          )
        else if (_hasError || _user == null)
          ErrorState(
            message: 'Could not load this profile. Please try again.',
            onRetry: _loadProfile,
          )
        else
          _buildProfileCard(_user!),
      ],
    );
  }

  Widget _buildProfileCard(User user) {
    final ImageProvider avatarImage =
        (user.photoUrl != null && user.photoUrl!.isNotEmpty)
        ? NetworkImage(user.fullPhotoUrl!)
        : const AssetImage('assets/images/splash-icon.png') as ImageProvider;

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            backgroundImage: avatarImage,
            onBackgroundImageError: (_, _) {},
            radius: 48,
            backgroundColor: AppColors.surfaceLight,
          ),
          const SizedBox(height: 16),
          Text(
            user.username,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${_formatRole(user.role)} • Campus Motion',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: _isFollowing ? 'Unfollow' : 'Follow',
            icon: _isFollowing
                ? Icons.person_remove_outlined
                : Icons.person_add_outlined,
            variant: _isFollowing
                ? AppButtonVariant.outline
                : AppButtonVariant.primary,
            isLoading: _isFollowLoading,
            onPressed: _toggleFollow,
          ),
        ],
      ),
    );
  }
}
