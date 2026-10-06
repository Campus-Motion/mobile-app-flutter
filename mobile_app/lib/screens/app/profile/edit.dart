import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/models/user_preferences.dart';
import 'package:mobile_app/models/health.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  bool _isLoading = true;
  User? _user;
  UserPreferences? _preferences;
  HealthData? _health;
  bool _hasHealthConsent = false;

  // Form Fields
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _bornController;

  // Preference Dropdown values
  String _selectedLevel = 'intermediate';
  String _selectedIntensity = 'moderate';
  String _selectedGoal = 'stay_active';
  List<String> _selectedSports = [];

  final List<String> _availableSports = [
    'run', 'walk', 'cycle', 'hike', 'swim', 'triathlon', 
    'climbing', 'volleyball', 'basketball', 'soccer', 
    'badminton', 'tennis', 'golf', 'other'
  ];

  final List<String> _availableLevels = ['beginner', 'intermediate', 'advanced', 'expert'];
  final List<String> _availableIntensities = ['light', 'moderate', 'intense', 'extreme'];
  final List<String> _availableGoals = [
    'lose_weight', 'build_muscle', 'improve_endurance', 'stay_active', 'compete', 'have_fun'
  ];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _bornController = TextEditingController();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
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

      setState(() {
        _user = user;
        _preferences = prefs;
        _health = health;
        _hasHealthConsent = health?.consentGivenAt != null;

        _usernameController.text = user.username;
        _emailController.text = user.email ?? '';
        _weightController.text = health?.weightKg != null ? health!.weightKg!.toStringAsFixed(0) : '';
        _heightController.text = health?.heightCm != null ? health!.heightCm!.toStringAsFixed(0) : '';
        _bornController.text = health?.born ?? '1998-11-05';

        _selectedLevel = _availableLevels.contains(prefs.level) ? prefs.level : 'intermediate';
        _selectedIntensity = _availableIntensities.contains(prefs.intensity) ? prefs.intensity : 'moderate';
        _selectedGoal = _availableGoals.contains(prefs.goal) ? prefs.goal : 'stay_active';
        _selectedSports = List<String>.from(prefs.preferredSports);
        
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile data: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    if (!_hasHealthConsent) return;
    DateTime initialDate = DateTime.tryParse(_bornController.text) ?? DateTime(1998, 11, 5);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _bornController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      // 1. Save user profile info
      await _userService.updateMe(
        username: _usernameController.text,
        email: _emailController.text,
      );

      // 2. Save user preferences
      final updatedPrefs = UserPreferences(
        preferredSports: _selectedSports,
        intensity: _selectedIntensity,
        goal: _selectedGoal,
        level: _selectedLevel,
        openToGroups: _preferences?.openToGroups ?? true,
        openToNewSports: _preferences?.openToNewSports ?? false,
        maxDistanceKm: _preferences?.maxDistanceKm ?? 25.0,
      );
      await _userService.updatePreferences(updatedPrefs);

      // 3. Save user health data
      if (_hasHealthConsent) {
        final weight = double.tryParse(_weightController.text);
        final height = double.tryParse(_heightController.text);
        final updatedHealth = HealthData(
          born: _bornController.text.isNotEmpty ? _bornController.text : '1998-11-05',
          weightKg: weight,
          heightCm: height,
          consentGivenAt: _health?.consentGivenAt ?? DateTime.now(),
          retainUntil: _health?.retainUntil ?? '2028-03-31',
        );

        if (_health == null) {
          await _userService.createHealth(updatedHealth);
        } else {
          await _userService.updateHealth(updatedHealth);
        }
      } else {
        if (_health != null) {
          await _userService.deleteHealth();
        }
      }

      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true); // Return success to refresh index screen
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _bornController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MasterContainer(
      children: [
        // Top Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
            const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            _isLoading
                ? const SizedBox(width: 48)
                : TextButton(
                    onPressed: _saveProfile,
                    child: const Text(
                      'Save',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
          ],
        ),
        const SizedBox(height: 30),
        
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 100.0),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          )
        else ...[
          // Avatar
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _user?.photoUrl != null
                      ? NetworkImage(_user!.fullPhotoUrl!)
                      : const AssetImage('assets/images/splash-icon.png') as ImageProvider,
                  backgroundColor: Colors.grey.shade200,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Form
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Public Info
                const Text('Public Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 15),
                _buildTextField('Username', _usernameController, (val) {}),
                _buildTextField('Email Address', _emailController, (val) {}, keyboardType: TextInputType.emailAddress),
                
                const SizedBox(height: 30),
                
                // 2. Preferences
                const Text('Activity Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 15),
                
                _buildDropdownField('Fitness Level', _selectedLevel, _availableLevels, (val) {
                  if (val != null) setState(() => _selectedLevel = val);
                }),
                
                _buildDropdownField('Workout Intensity', _selectedIntensity, _availableIntensities, (val) {
                  if (val != null) setState(() => _selectedIntensity = val);
                }),
                
                _buildDropdownField('Primary Goal', _selectedGoal, _availableGoals, (val) {
                  if (val != null) setState(() => _selectedGoal = val);
                }),

                const SizedBox(height: 15),
                const Text('Preferred Sports', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _availableSports.map((sport) {
                    final isSelected = _selectedSports.contains(sport);
                    return FilterChip(
                      label: Text(sport),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.primary,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSports.add(sport);
                          } else {
                            _selectedSports.remove(sport);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 30),

                // 3. Physical Data (Private)
                const Text('Physical Data (Private & Encrypted)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 10),
                CheckboxListTile(
                  title: const Text(
                    'I consent to the collection and processing of my physical/health data (weight, height, age) to personalize my fitness experience.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  value: _hasHealthConsent,
                  onChanged: (val) {
                    setState(() {
                      _hasHealthConsent = val ?? false;
                      if (!_hasHealthConsent) {
                        _weightController.clear();
                        _heightController.clear();
                        _bornController.text = '1998-11-05';
                      }
                    });
                  },
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 10),
                
                Row(
                  children: [
                    Expanded(child: _buildTextField('Weight (kg)', _weightController, (val) {}, keyboardType: TextInputType.number, enabled: _hasHealthConsent)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildTextField('Height (cm)', _heightController, (val) {}, keyboardType: TextInputType.number, enabled: _hasHealthConsent)),
                  ],
                ),
                
                GestureDetector(
                  onTap: _selectDate,
                  child: AbsorbPointer(
                    child: _buildTextField('Date of Birth', _bornController, (val) {}, icon: Icons.calendar_today, enabled: _hasHealthConsent),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, Function(String) onSave, {TextInputType keyboardType = TextInputType.text, IconData? icon, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          suffixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (label == 'Username' && (value == null || value.trim().isEmpty)) {
            return 'Username cannot be empty';
          }
          if (label == 'Email Address' && (value == null || value.trim().isEmpty)) {
            return 'Email cannot be empty';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items.map((item) {
          final displayItem = item.replaceAll('_', ' ');
          final capitalized = displayItem[0].toUpperCase() + displayItem.substring(1);
          return DropdownMenuItem<String>(
            value: item,
            child: Text(capitalized),
          );
        }).toList(),
      ),
    );
  }
}
