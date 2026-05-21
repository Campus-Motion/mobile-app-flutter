import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/services/auth_service.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _isMetric = true;
  bool _pushNotifications = true;
  bool _privateAccount = false;

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

        // Account Section
        _buildSectionHeader('Account'),
        _buildListTile('Change Email/Password', Icons.lock_outline, () {}),
        _buildListTile('Connect Devices', Icons.devices, () {}),
        
        // Preferences Section
        _buildSectionHeader('Preferences'),
        SwitchListTile(
          title: const Text('Use Metric Units (km/kg)'),
          value: _isMetric,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _isMetric = val),
        ),
        SwitchListTile(
          title: const Text('Push Notifications'),
          value: _pushNotifications,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _pushNotifications = val),
        ),

        // Privacy Section
        _buildSectionHeader('Privacy'),
        SwitchListTile(
          title: const Text('Private Account'),
          subtitle: const Text('Only approved followers can see your activities'),
          value: _privateAccount,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _privateAccount = val),
        ),
        _buildListTile('Blocked Users', Icons.block, () {}),

        const SizedBox(height: 40),

        // Logout Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
                
                await AuthService().logout();
                
                if (mounted) {
                  Navigator.pop(context); // Dismiss dialog
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                }
              },
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
