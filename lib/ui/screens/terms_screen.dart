import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coral = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(150)
        ?? Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Terms of Service',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Last updated: June 2026',
                style: TextStyle(color: muted, fontSize: 13)),
            const SizedBox(height: 20),

            // Summary box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: coral.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: coral.withAlpha(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Summary',
                      style: TextStyle(
                          color: coral,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 8),
                  const Text(
                    'Peteks is a free notes app. Your data stays on your device. We don\'t take responsibility for data loss — please back up your notes. By using the app you accept these terms.',
                    style: TextStyle(fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _Section(context, '1. Acceptance of Terms', coral,
              'By downloading, installing, or using Peteks ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree with any part of these Terms, you must not use the App.',
            ),

            _Section(context, '2. Description of Service', coral,
              'Peteks is a personal note-taking application that stores your notes locally on your device. Optional features include Google Drive backup (requires your explicit authorization) and anonymous crash/usage analytics via Firebase.',
            ),

            _Section(context, '3. No Personal Data Collection', coral,
              'Peteks does NOT collect, store, or transmit any personally identifiable information on our servers. Specifically:\n\n• Your note content is stored exclusively on your device.\n• We do not collect your name, email, phone number, or any identifying information.\n• We do not read, access, or monitor your notes at any time.\n• Firebase Analytics collects only anonymous usage statistics (e.g. "app opened"). No note content is included.\n• Firebase Crashlytics collects anonymous crash reports (device model, OS version) only.\n• If you use Google Drive backup, your data is sent directly to YOUR personal Google Drive — not to our servers.',
            ),

            _Section(context, '4. No Warranty / Disclaimer', coral,
              'THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO:\n\n• Warranties of merchantability or fitness for a particular purpose.\n• Warranties that the App will be uninterrupted, error-free, or secure.\n• Warranties that any defects will be corrected.\n\nYou use the App entirely at your own risk.',
            ),

            _Section(context, '5. Limitation of Liability — Data Loss', coral,
              'TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, PETEKS AND ITS DEVELOPER SHALL NOT BE LIABLE FOR:\n\n• Any loss, corruption, or deletion of your notes or data, whether caused by app bugs, device failure, accidental deletion, uninstallation, or any other reason.\n• Any indirect, incidental, special, consequential, or punitive damages.\n• Loss of business, profits, revenue, or data.\n\nYOU ARE SOLELY RESPONSIBLE FOR BACKING UP YOUR OWN DATA. We strongly recommend enabling Google Drive backup in the app settings.',
            ),

            _Section(context, '6. User Responsibilities', coral,
              'You agree that you will:\n\n• Use the App only for lawful purposes and in accordance with applicable laws.\n• Not use the App to store illegal, harmful, or offensive content.\n• Take responsibility for maintaining backups of your important data.\n• Keep your device and any security credentials (passwords, patterns) safe.\n• Not attempt to reverse-engineer, decompile, or tamper with the App.',
            ),

            _Section(context, '7. User Content', coral,
              'You retain full ownership of all notes, text, images, and audio recordings ("Content") you create in the App. By using the App, you represent that:\n\n• You have the right to create and store such Content.\n• Your Content does not violate any applicable laws or third-party rights.\n\nWe claim no ownership over your Content and will never access it.',
            ),

            _Section(context, '8. Google Drive Integration', coral,
              'If you choose to use the Google Drive backup feature:\n\n• You must authorize access through your Google account.\n• Your data is transferred directly to your own Google Drive storage.\n• You are subject to Google\'s Terms of Service and Privacy Policy.\n• We do not store your Google credentials or access tokens on our servers.\n• You can revoke access at any time from your Google account settings.',
            ),

            _Section(context, '9. Intellectual Property', coral,
              'All intellectual property rights in the App (including its design, code, and branding) are owned by Peteks. The Nunito font is licensed under the SIL Open Font License 1.1. You may not copy, modify, distribute, or create derivative works of the App without prior written permission.',
            ),

            _Section(context, '10. Termination', coral,
              'We reserve the right to discontinue the App or any of its features at any time without notice. Upon uninstallation, all locally stored data will be removed from your device. Any Google Drive backups remain in your Drive and are your responsibility to manage.',
            ),

            _Section(context, '11. Changes to These Terms', coral,
              'We may update these Terms from time to time. The "Last updated" date at the top will be revised. For significant changes, we will notify users via an in-app notice. Continued use of the App after changes constitutes acceptance of the new Terms.',
            ),

            _Section(context, '12. Governing Law', coral,
              'These Terms shall be governed by applicable law. Any disputes arising from these Terms or the use of the App shall be resolved through good-faith negotiation. If a resolution cannot be reached, disputes shall be subject to binding arbitration or the jurisdiction of the competent courts where the developer is located.',
            ),

            _Section(context, '13. Contact', coral,
              'For any questions, concerns, or requests regarding these Terms:',
            ),

            // Contact card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [coral.withAlpha(38), coral.withAlpha(13)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: coral.withAlpha(76)),
              ),
              child: Column(
                children: [
                  const Text('Questions about these terms?',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        launchUrl(Uri.parse('mailto:info@peteksapp.com')),
                    child: Text('info@peteksapp.com',
                        style: TextStyle(
                            color: coral,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ),
                  Text('We respond within 30 days.',
                      style: TextStyle(color: muted, fontSize: 12)),
                ],
              ),
            ),

            Center(child: Image.asset('assets/peteks.png', height: 60)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

Widget _Section(BuildContext context, String title, Color coral, String body) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: coral,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                fontFamily: 'Nunito')),
        const SizedBox(height: 8),
        Text(body,
            style: const TextStyle(fontSize: 14, height: 1.65)),
      ],
    ),
  );
}
