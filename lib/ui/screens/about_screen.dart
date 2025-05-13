import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 12),
                        const Text(
                          'About Peteks',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Peteks is a beautiful, secure, and feature-rich notes app. All your notes are stored locally and can be organized with tags, favorites, and pinning. You can secure notes with a password or pattern, and even hide them from the main view for extra privacy. Use the secret corner for private notes! Enjoy a smooth, modern UI with light and dark themes.',
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '''How to use:
• Tap + to create a new note.
• Tap a note to view or edit it.
• Use the heart to favorite, the pin to pin, and the tag bar to filter.
• Secure a note from the note menu (three dots > Secure Note).
• To view secure notes, tap the secret corner in the home screen.
• All your data stays on your device unless you enable Google Drive sync.''',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Image.asset(
                'assets/peteks.png',
                height: 96,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
