import 'package:flutter/material.dart';
import '../widgets/store_badges.dart';

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
              'Last updated: March 2024',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Information Collection',
              'Peteks collects and stores your notes and images locally on your device. '
                  'We do not collect any personal information or usage data.',
            ),
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
            const Center(
              child: Text(
                'Download Peteks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const StoreBadges(height: 48),
            const SizedBox(height: 32),
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
