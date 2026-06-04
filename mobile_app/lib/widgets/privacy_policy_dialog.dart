import 'package:flutter/material.dart';
import 'package:mobile_app/constants/colors.dart';

class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PrivacyPolicyDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('1. Overview'),
                    _buildSectionBody(
                      'Welcome to Campus Motion. We are committed to protecting your personal data and respecting your privacy in compliance with the General Data Protection Regulation (GDPR).',
                    ),
                    _buildSectionTitle('2. Information We Collect'),
                    _buildSectionBody(
                      '• Account Information: Username, email, password.\n'
                      '• Fitness Preferences: Preferred sports, levels, workout intensity, goals, distance settings.\n'
                      '• Sensitive Health Data: Weight, height, age/date of birth (if explicitly consented). This data is encrypted before transmission.',
                    ),
                    _buildSectionTitle('3. Health Data & Explicit Consent'),
                    _buildSectionBody(
                      'Processing of physical health data is based solely on your explicit, opt-in consent (GDPR Art. 9). You can grant or revoke this consent at any time via the "Edit Profile" screen. If you revoke consent, your health data will be immediately deleted from our active servers.',
                    ),
                    _buildSectionTitle('4. Storage Limitation'),
                    _buildSectionBody(
                      'We only retain your health data as long as necessary. By default, it is retained for a maximum of 2 years (or until a deletion request is made) after which it is automatically purged.',
                    ),
                    _buildSectionTitle('5. Your Rights Under GDPR'),
                    _buildSectionBody(
                      '• Right to be Informed: Transparent information about your data processing.\n'
                      '• Right of Access & Portability: Download your complete profile, preferences, health data, and activity records in JSON format via settings.\n'
                      '• Right to Rectification: Correct inaccurate data on your Edit Profile screen.\n'
                      '• Right to Erasure (Right to be Forgotten): Delete your health records or erase your entire account via settings.\n'
                      '• Right to Restrict Processing: Halt further processing of your physical data at any time by withdrawing consent.',
                    ),
                    _buildSectionTitle('6. Contact Us'),
                    _buildSectionBody(
                      'For questions regarding your privacy rights, please contact our Data Protection Officer at privacy@campusmotion.ch.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Dismiss',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSectionBody(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black54,
        height: 1.4,
      ),
    );
  }
}
