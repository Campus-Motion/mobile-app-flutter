import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/widgets/privacy_policy_dialog.dart';
import 'package:mobile_app/models/user_preferences.dart';
import 'package:mobile_app/models/health.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final UserService _userService = UserService();
  UserPreferences? _preferences;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await _userService.getPreferences();
      setState(() {
        _preferences = prefs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _preferences = UserPreferences.empty();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load preferences. Using defaults.')),
        );
      }
    }
  }

  Future<void> _updatePref(UserPreferences newPrefs) async {
    final oldPrefs = _preferences;
    setState(() => _preferences = newPrefs);
    try {
      await _userService.updatePreferences(newPrefs);
    } catch (e) {
      setState(() => _preferences = oldPrefs);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save preferences')),
        );
      }
    }
  }

  Future<void> _exportData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final user = await _userService.getMe();
      
      UserPreferences prefs;
      try {
        prefs = await _userService.getPreferences();
      } catch (_) {
        prefs = UserPreferences.empty();
      }

      HealthData? health;
      try {
        health = await _userService.getHealth();
      } catch (_) {
        health = null;
      }

      List<dynamic> activitiesJson = [];
      try {
        final activities = await ActivityService().getActivities(limit: 100);
        activitiesJson = activities.map((a) => a.toJson()).toList();
      } catch (_) {}

      final exportMap = {
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'app': 'Campus Motion',
        'user': user.toJson(),
        'preferences': prefs.toJson(),
        'health_data': health?.toJson(),
        'activities': activitiesJson,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportMap);

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      await SharePlus.instance.share(
        ShareParams(
          text: jsonString,
          subject: 'Campus Motion Data Export',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export data: $e')),
      );
    }
  }

  Future<void> _confirmDeleteHealth() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Health Data'),
        content: const Text(
          'Are you sure you want to permanently delete your physical and health data (weight, height, age) from our servers? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      try {
        await _userService.deleteHealth();
        if (!mounted) return;
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health data deleted successfully.')),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete health data: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'WARNING: This will permanently delete your account, preferences, activities, and physical records. All data will be immediately erased from our servers in compliance with GDPR. This action is irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Permanently Delete'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      try {
        await _userService.deleteMe();
        await AuthService().logout();
        
        if (!mounted) return;
        Navigator.pop(context); // Dismiss loading dialog
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your account and all associated data have been permanently deleted.')),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    await AuthService().logout();

    if (!mounted) return;
    Navigator.pop(context); // Dismiss dialog
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return MasterContainer(
      padding: EdgeInsets.zero,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'Settings',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance for the back button
            ],
          ),
        ),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          )
        else if (_preferences != null) ...[
          // Account Section
          _buildSectionHeader('Account'),
          _buildListTile('Change Email/Password', Icons.lock_outline, () {}),
          _buildListTile('Connect Devices', Icons.devices, () {}),
          
          // Sport Preferences Section
          _buildSectionHeader('Sport Preferences'),
          SwitchListTile(
            title: const Text('Open to Group Activities'),
            value: _preferences!.openToGroups,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => _updatePref(_preferences!.copyWith(openToGroups: val)),
          ),
          SwitchListTile(
            title: const Text('Open to New Sports'),
            value: _preferences!.openToNewSports,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => _updatePref(_preferences!.copyWith(openToNewSports: val)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Max Distance: ${_preferences!.maxDistanceKm.toStringAsFixed(1)} km', 
                  style: const TextStyle(fontSize: 16)
                ),
                Slider(
                  value: _preferences!.maxDistanceKm,
                  min: 1.0,
                  max: 100.0,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _preferences = _preferences!.copyWith(maxDistanceKm: val);
                    });
                  },
                  onChangeEnd: (val) {
                    _updatePref(_preferences!.copyWith(maxDistanceKm: val));
                  },
                ),
              ],
            ),
          ),

          // Activity Goal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Primary Goal', style: TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  value: _preferences!.goal,
                  items: const [
                    DropdownMenuItem(value: 'stay_active', child: Text('Stay Active')),
                    DropdownMenuItem(value: 'lose_weight', child: Text('Lose Weight')),
                    DropdownMenuItem(value: 'build_muscle', child: Text('Build Muscle')),
                    DropdownMenuItem(value: 'improve_endurance', child: Text('Improve Endurance')),
                    DropdownMenuItem(value: 'compete', child: Text('Compete')),
                    DropdownMenuItem(value: 'have_fun', child: Text('Have Fun')),
                  ],
                  onChanged: (val) {
                    if (val != null) _updatePref(_preferences!.copyWith(goal: val));
                  },
                ),
              ],
            ),
          ),

          // Privacy & Data Section
          _buildSectionHeader('Privacy & Data'),
          _buildListTile('Privacy Policy', Icons.privacy_tip_outlined, () {
            PrivacyPolicyDialog.show(context);
          }),
          _buildListTile('Export My Data', Icons.download_outlined, () => _exportData()),
          _buildListTile('Delete Health Data', Icons.delete_outline, () => _confirmDeleteHealth()),
          _buildListTile('Delete Account', Icons.no_accounts_outlined, () => _confirmDeleteAccount()),

          const SizedBox(height: 40),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(color: Colors.red),
                  ),
                  elevation: 0,
                ),
                child: const Text('Log Out', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 30, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
