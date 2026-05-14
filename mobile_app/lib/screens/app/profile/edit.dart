import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/constants/colors.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Mock initial values
  String _username = 'Forrest Gump';
  String _bio = 'Mom always said : Life is like a box of chocolate...';
  String _affiliation = 'EPFL Student';
  String _location = 'Greenbow, Alabama';
  String _weight = '75';
  String _height = '185';
  String _gender = 'Male';

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
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  // Save logic would go here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!')),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        
        // Avatar Edit
        Center(
          child: Stack(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/splash-icon.png'),
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
              const Text('Public Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 15),
              _buildTextField('Username', _username, (val) => _username = val),
              _buildTextField('Bio', _bio, (val) => _bio = val, maxLines: 3),
              _buildTextField('Affiliation', _affiliation, (val) => _affiliation = val),
              _buildTextField('Location', _location, (val) => _location = val),
              
              const SizedBox(height: 30),
              const Text('Physical Data (Private)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 15),
              
              Row(
                children: [
                  Expanded(child: _buildTextField('Weight (kg)', _weight, (val) => _weight = val, keyboardType: TextInputType.number)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildTextField('Height (cm)', _height, (val) => _height = val, keyboardType: TextInputType.number)),
                ],
              ),
              _buildTextField('Gender', _gender, (val) => _gender = val),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String initialValue, Function(String) onSave, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        initialValue: initialValue,
        maxLines: maxLines,
        keyboardType: keyboardType,
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
        onSaved: (value) {
          if (value != null) {
            onSave(value);
          }
        },
      ),
    );
  }
}
