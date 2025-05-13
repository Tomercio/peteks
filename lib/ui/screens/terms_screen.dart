import 'package:flutter/material.dart';
import '../widgets/store_badges.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Service',
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
            _buildSection(
              '1. Acceptance of Terms',
              'By downloading, installing, or using Peteks, you agree to be bound by these Terms of Service.',
            ),
            _buildSection(
              '2. Use of Service',
              'Peteks is provided for personal, non-commercial use. You are responsible for maintaining the confidentiality of your data.',
            ),
            _buildSection(
              '3. User Content',
              'You retain all rights to your content. You are solely responsible for the content you create and store using Peteks.',
            ),
            _buildSection(
              '4. Disclaimer',
              'Peteks is provided "as is" without any warranties. We are not responsible for any loss of data or other damages.',
            ),
            _buildSection(
              '5. Limitation of Liability',
              'To the maximum extent permitted by law, Peteks and its developers shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of data, use, or other intangible losses, resulting from your use of the app.',
            ),
            _buildSection(
              '6. No Warranty',
              'Peteks is provided "as is" and "as available" without any warranties of any kind, either express or implied.',
            ),
            _buildSection(
              '7. User Responsibilities',
              'You are solely responsible for backing up your data and for compliance with all applicable laws.',
            ),
            _buildSection(
              '8. Termination',
              'We reserve the right to terminate or suspend your access to Peteks at any time, without notice, for any reason.',
            ),
            _buildSection(
              '9. Governing Law',
              'These terms are governed by the laws of Israel, without regard to its conflict of law principles.',
            ),
            _buildSection(
              '10. Contact',
              'For any questions or concerns, contact us at info.peteks@gmail.com.',
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
