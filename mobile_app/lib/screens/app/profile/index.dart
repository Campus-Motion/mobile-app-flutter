import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/config/routes.dart';
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

  int _activityCount = 0;
  double _totalDistanceKm = 0.0;
  double _totalDurationMinutes = 0.0;

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

      double durationSum = 0.0;
      double distanceSum = 0.0;

      for (var act in activities) {
        if (act.duration != null) {
          durationSum += act.duration!;
          
          // Estimate distance based on average speeds for different activities
          double speedKmh = 5.0; // Default walking/other speed
          switch (act.type.toLowerCase()) {
            case 'run':
              speedKmh = 10.0;
              break;
            case 'walk':
              speedKmh = 5.0;
              break;
            case 'cycle':
              speedKmh = 20.0;
              break;
            case 'hike':
              speedKmh = 4.0;
              break;
            case 'swim':
              speedKmh = 2.0;
              break;
          }
          distanceSum += speedKmh * (act.duration! / 60.0);
        }
      }

      setState(() {
        _user = user;
        _preferences = prefs;
        _activities = activities;
        _activityCount = activities.length;
        _totalDurationMinutes = durationSum;
        _totalDistanceKm = distanceSum;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile data: $e')),
      );
    }
  }

  static dynamic _navigationFunction(BuildContext context, int index){
    switch(index) {
      case 0 : 
        return Navigator.pushNamed(context, AppRoutes.dashboard);
      case 1 :
        return Navigator.pushNamed(context, AppRoutes.trail);
      case 2 :
        return Navigator.pushNamed(context, AppRoutes.social);
      case 3 : 
        return Navigator.pushNamed(context, AppRoutes.profile);
      case _ :
        return Navigator.pushNamed(context, AppRoutes.dashboard);
    }
  }

  void _shareProfile() {
    final username = _user?.username ?? 'a Campus Motion member';
    Share.share('Check out $username\'s Campus Motion profile! Join me and track your campus activities.');
  }

  String _formatDuration(double totalMinutes) {
    final int hours = (totalMinutes / 60).floor();
    final int minutes = (totalMinutes % 60).round();
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _getActivityDurationString(double? minutes) {
    if (minutes == null) return '--';
    final int hrs = (minutes / 60).floor();
    final int mins = (minutes % 60).round();
    if (hrs > 0) {
      return '${hrs}h ${mins}m';
    }
    return '${mins}m';
  }

  String _getActivityDistanceString(double? minutes, String type) {
    if (minutes == null) return '--';
    double speedKmh = 5.0;
    switch (type.toLowerCase()) {
      case 'run': speedKmh = 10.0; break;
      case 'walk': speedKmh = 5.0; break;
      case 'cycle': speedKmh = 20.0; break;
      case 'hike': speedKmh = 4.0; break;
      case 'swim': speedKmh = 2.0; break;
    }
    final distance = speedKmh * (minutes / 60.0);
    return '${distance.toStringAsFixed(1)} km';
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
      bottomNavigationBar: CampusMotionBottomBar(currentIndex: 3, onTap: _navigationFunction, context: context),
      onRefresh: _loadProfileData,
      children : [
        // Top Navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children : [
            OutlinedButton.icon(
              onPressed : () => Navigator.pushNamed(context, AppRoutes.editProfile).then((_) => _loadProfileData()),
              icon : const Icon(Icons.edit, size: 16, color: AppColors.primary),
              label: const Text('Edit', style: TextStyle(color:AppColors.primary)),
              style: OutlinedButton.styleFrom(
                side : const BorderSide(width: 1, color : AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              )
            ),
            const Image(height : 40, image: AssetImage('assets/images/logo_peach.png')),
            Row(
              children : [
                IconButton(
                  icon: const Icon(Icons.ios_share),
                  onPressed : _shareProfile,
                  color: AppColors.primary
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.parameters).then((_) => _loadProfileData()),
                  color : AppColors.primary
                )
              ]
            )
          ]
        ),
        const SizedBox(height: 30),
        
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 100.0),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          )
        else ...[
          // Profile Header
          Column(
            children: [
              CircleAvatar(
                backgroundImage: _user?.photoUrl != null
                    ? NetworkImage(_user!.fullPhotoUrl!)
                    : const AssetImage('assets/images/splash-icon.png') as ImageProvider,
                radius: 45,
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(height: 15),
              Text(
                username,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 5),
              Text(
                '$formattedRole Member • Campus Motion',
                style: const TextStyle(color: Colors.grey, fontSize: 14)
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  bioText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),

          // Stats Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Activities', '$_activityCount'),
              _buildStatCard('Distance', '${_totalDistanceKm.toStringAsFixed(0)} km'),
              _buildStatCard('Active Time', _formatDuration(_totalDurationMinutes)),
            ],
          ),

          const SizedBox(height: 40),

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
                    Icon(Icons.directions_run_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    Text(
                      'No activities tracked yet.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._activities.take(5).map((activity) {
              final formattedDate = DateFormat('MMM d, yyyy').format(activity.createdAt);
              return _buildActivityCard(
                icon: _getActivityIcon(activity.type),
                title: activity.title,
                date: formattedDate,
                distance: _getActivityDistanceString(activity.duration, activity.type),
                duration: _getActivityDurationString(activity.duration),
              );
            }),
        ],
      ]
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildActivityCard({required IconData icon, required String title, required String date, required String distance, required String duration}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(distance, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(duration, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}
