import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/widgets/activity_card.dart';
import 'package:mobile_app/widgets/app_button.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/bottom_bar.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/models/activity.dart';
import 'package:mobile_app/models/user_preferences.dart';

class ProfileIndexScreen extends StatefulWidget {
  const ProfileIndexScreen({super.key});

  @override
  State<ProfileIndexScreen> createState() => _ProfileIndexScreenState();
}

class _ProfileIndexScreenState extends State<ProfileIndexScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final ActivityService _activityService = ActivityService();

  User? _user;
  UserPreferences? _preferences;
  List<Activity> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.getProfile();
      UserPreferences? prefs;
      try {
        prefs = await _userService.getPreferences();
      } catch (_) {
        prefs = UserPreferences.empty();
      }

      final activities = await _activityService.getActivities(limit: 50);

      if (!mounted) return;
      setState(() {
        _user = user;
        _preferences = prefs;
        _activities = activities;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load profile data. Please try again.'),
        ),
      );
    }
  }

  void _shareProfile() {
    final username = _user?.username ?? 'a Campus Motion member';
    SharePlus.instance.share(
      ShareParams(
        text:
            'Check out $username\'s Campus Motion profile! Join me and track your campus activities.',
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'run':
        return Icons.directions_run;
      case 'walk':
        return Icons.directions_walk;
      case 'cycle':
        return Icons.pedal_bike;
      case 'hike':
        return Icons.terrain;
      case 'swim':
        return Icons.pool;
      case 'climbing':
        return Icons.filter_hdr;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = _user?.username ?? 'Forrest Gump';
    final role = _user?.role ?? 'user';
    final formattedRole = role[0].toUpperCase() + role.substring(1);

    // Build bio based on preferences
    String bioText = "No preferences set yet.";
    if (_preferences != null && _preferences!.preferredSports.isNotEmpty) {
      final sports = _preferences!.preferredSports.join(', ');
      final intensity = _preferences!.intensity;
      final level = _preferences!.level;
      bioText = "${level.toUpperCase()} • Prefers: $sports ($intensity)";
    }

    return MasterContainer(
      bottomNavigationBar: const CampusMotionBottomBar(currentIndex: 3),
      onRefresh: _loadProfileData,
      children: [
        // Top Navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.editProfile,
              ).then((_) => _loadProfileData()),
              icon: const Icon(Icons.edit, size: 16, color: AppColors.primary),
              label: const Text(
                'Edit',
                style: TextStyle(color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(width: 1, color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const Image(
              height: 40,
              image: AssetImage('assets/images/logo_peach.png'),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.ios_share),
                  onPressed: _shareProfile,
                  color: AppColors.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.settings,
                  ).then((_) => _loadProfileData()),
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 30),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 100.0),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else ...[
          // Profile Header
          Column(
            children: [
              CircleAvatar(
                backgroundImage: _user?.photoUrl != null
                    ? NetworkImage(_user!.fullPhotoUrl!)
                    : const AssetImage('assets/images/splash-icon.png')
                          as ImageProvider,
                radius: 45,
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(height: 15),
              Text(
                username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$formattedRole Member • Campus Motion',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  bioText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          AppButton(
            text: 'My Heatmaps & Statistics',
            icon: Icons.map_outlined,
            variant: AppButtonVariant.outline,
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.heatmaps);
              if (!mounted) return;
              _loadProfileData();
            },
          ),

          const SizedBox(height: 32),

          // Recent Activities
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Recent Activities',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 15),

          if (_activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_run_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No activities tracked yet.',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._activities.take(5).map((activity) {
              final formattedDate = DateFormat(
                'MMM d, yyyy',
              ).format(activity.createdAt);
              return _buildActivityCard(
                icon: _getActivityIcon(activity.type),
                title: activity.title,
                date: formattedDate,
                distance: ActivityCard.getActivityDistanceString(activity),
                duration: ActivityCard.getActivityDurationString(
                  activity.duration,
                ),
              );
            }),
        ],
      ],
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required String date,
    required String distance,
    required String duration,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                distance,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                duration,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
