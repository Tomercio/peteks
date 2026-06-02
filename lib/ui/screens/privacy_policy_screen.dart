import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coral = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)
        ?? Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('Privacy Policy',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Last updated: May 30, 2026',
                style: TextStyle(color: muted, fontSize: 13)),
            const SizedBox(height: 20),

            // Plain English summary box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: coral.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: coral.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Summary',
                      style: TextStyle(color: coral, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  const Text(
                    'Peteks stores your notes on your device only. We don\'t sell your data, show ads, or read what you write. The only data that leaves your device is anonymous crash reports (Firebase) and your backup if you choose to use Google Drive.',
                    style: TextStyle(fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Quick badges
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _Badge('🚫 No Ads', coral),
                _Badge('📵 No Tracking', coral),
                _Badge('🔐 GDPR Compliant', coral),
                _Badge('⚖️ CCPA Compliant', coral),
                _Badge('👶 No Child Data', coral),
                _Badge('⚡ 30-Day Response', coral),
              ],
            ),
            const SizedBox(height: 32),

            _Section(context, '1. Who We Are',
              'Peteks is a personal notes application developed by an independent developer.\n\nContact: info@peteksapp.com\nWebsite: peteksapp.com',
            ),

            _Section(context, '2. What Data We Collect',
              'We collect the minimum possible:',
              bullets: [
                '📝 Notes content — stored locally on YOUR device only (Hive DB). Never sent to our servers.',
                '📊 Firebase Analytics — anonymous usage events only (e.g. "app opened"). No note content, no name, no email.',
                '💥 Firebase Crashlytics — anonymous crash reports (device model, OS version). No personal data.',
                '🔑 Google Account — ONLY if you use Google Drive backup. Not stored by us.',
                '☁️ Google Drive — your backup goes to YOUR own Drive. We cannot access it.',
              ],
            ),

            _Section(context, '3. What We NEVER Collect',
              '',
              bullets: [
                '❌ We never read or store your note content on our servers',
                '❌ We never sell your data to anyone',
                '❌ We never show advertisements',
                '❌ We never collect your location',
                '❌ We never share data with advertisers or data brokers',
                '❌ We never collect data from children under 13',
              ],
            ),

            _Section(context, '4. Third-Party Services',
              'The following third-party services are used:',
              bullets: [
                'Firebase Analytics (Google) — anonymous usage stats only',
                'Firebase Crashlytics (Google) — anonymous crash reports only',
                'Google Sign-In — only when you use Drive backup',
                'Google Drive API — only when you use Drive backup',
              ],
              note: 'None of these services receive your note content.',
            ),

            _Section(context, '5. Data Retention',
              '',
              bullets: [
                'Notes — on your device until you delete them or uninstall the app',
                'Google Drive backup — in your Drive until you delete it manually',
                'Firebase crash/analytics data — max 90 days, then auto-deleted by Google',
                'Google Sign-In token — on your device until you sign out from Settings',
              ],
            ),

            _Section(context, '6. Security',
              'We take security seriously:',
              bullets: [
                'Secure notes use HMAC-SHA256 hashing with a unique per-note salt',
                'Passwords and patterns are NEVER stored in plain text',
                'All cloud communication uses HTTPS/TLS encryption',
                'We have no access to your device or local notes',
              ],
            ),

            _Section(context, '7. Children\'s Privacy',
              'Peteks is not directed at children under 13 (or 16 in the EU). We do not knowingly collect personal information from children. If you believe a child has used the app and provided personal data, contact us immediately at info@peteksapp.com and we will delete it.',
            ),

            // GDPR Box
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: coral.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: coral.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('8. Your Rights — GDPR (EU Users)',
                      style: TextStyle(color: coral, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  const Text('If you are in the EU/EEA, you have the right to:',
                      style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 10),
                  ...[
                    ('📋', 'Access', 'Request a copy of your personal data'),
                    ('✏️', 'Rectification', 'Request correction of inaccurate data'),
                    ('🗑️', 'Erasure', 'Request deletion ("right to be forgotten")'),
                    ('⏸️', 'Restriction', 'Request we restrict processing'),
                    ('📦', 'Portability', 'Receive your data in machine-readable format'),
                    ('🚫', 'Object', 'Object to processing based on legitimate interests'),
                  ].map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.$1, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Expanded(child: RichText(text: TextSpan(
                          style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.white70),
                          children: [
                            TextSpan(text: '${r.$2}: ', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                            TextSpan(text: r.$3),
                          ],
                        ))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
                  Text('Contact info@peteksapp.com — we respond within 30 days.',
                      style: TextStyle(color: muted, fontSize: 13)),
                ],
              ),
            ),

            // CCPA Box
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('9. Your Rights — CCPA (California Users)',
                      style: TextStyle(color: coral, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...[
                    'Right to Know — what personal data we collect and how we use it',
                    'Right to Delete — request deletion of your personal data',
                    'Right to Opt-Out — we do NOT sell personal data (nothing to opt out of)',
                    'Right to Non-Discrimination — we will not discriminate for exercising your rights',
                  ].map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: coral, fontWeight: FontWeight.bold)),
                        Expanded(child: Text(t, style: const TextStyle(fontSize: 13, height: 1.5))),
                      ],
                    ),
                  )),
                ],
              ),
            ),

            _Section(context, '10. Changes to This Policy',
              'We may update this policy from time to time. The "Last updated" date at the top will be revised. For significant changes, we will notify users via an in-app notice.',
            ),

            _Section(context, '11. Contact Us',
              'For any privacy questions, requests, or concerns — we respond within 30 days:',
            ),

            // Contact card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [coral.withOpacity(0.15), coral.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: coral.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text('Questions about your privacy?',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse('mailto:info@peteksapp.com')),
                    child: Text('info@peteksapp.com',
                        style: TextStyle(color: coral, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse('https://peteksapp.com/privacy.html'),
                        mode: LaunchMode.externalApplication),
                    child: Text('View full policy online →',
                        style: TextStyle(color: muted, fontSize: 13)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            Center(child: Image.asset('assets/peteks.png', height: 60)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

Widget _Section(BuildContext context, String title, String body, {
  List<String> bullets = const [],
  String? note,
}) {
  final coral = Theme.of(context).colorScheme.primary;
  final muted = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey;
  return Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: coral, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 10),
        if (body.isNotEmpty)
          Text(body, style: const TextStyle(fontSize: 14, height: 1.65)),
        if (bullets.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...bullets.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 4),
                Expanded(child: Text(b, style: const TextStyle(fontSize: 13, height: 1.6))),
              ],
            ),
          )),
        ],
        if (note != null) ...[
          const SizedBox(height: 8),
          Text(note, style: TextStyle(color: muted, fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ],
    ),
  );
}
