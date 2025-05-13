import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last updated: May 2025',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection('Information Collection',
                'Peteks does not collect, store, or transmit any personal information to our servers. All notes and images are stored locally on your device. If you choose to use Google Drive sync, your data is transmitted securely to your own Google Drive account and is subject to Google’s privacy policy.'),
            _buildSection('Third-Party Services',
                'If you use Google Drive sync, please review Google’s Privacy Policy at https://policies.google.com/privacy. We do not share your data with any other third parties.'),
            _buildSection('Security',
                'We use secure storage methods to protect your data on your device. However, no method of electronic storage is 100% secure, and we cannot guarantee absolute security.'),
            _buildSection('Children’s Privacy',
                'Peteks is not intended for children under 13. We do not knowingly collect information from children.'),
            _buildSection('User Rights',
                'You have the right to delete your data at any time by uninstalling the app. For any questions, contact us at info.peteks@gmail.com.'),
            _buildSection('Changes to This Policy',
                'We may update our Privacy Policy from time to time. Changes will be posted in the app or on our website.'),
            _buildSection(
              'Data Storage',
              'All your notes and images are stored locally on your device. '
                  'We use secure storage methods to protect your data.',
            ),
            _buildSection(
              'Permissions',
              'Peteks requires the following permissions:\n'
                  '• Storage access: To save and load your notes and images\n'
                  '• Camera access: To take photos for your notes\n'
                  '• Photo library access: To select images from your gallery',
            ),
            _buildSection(
              'Contact',
              'If you have any questions about this Privacy Policy, '
                  'please contact us at info.peteks@gmail.com',
            ),
            const SizedBox(height: 32),
            Center(
              child: Image.asset(
                'assets/peteks.png',
                height: 60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
