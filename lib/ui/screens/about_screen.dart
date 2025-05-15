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
                      'Peteks is a beautiful, secure, and feature-rich notes app designed to help you organize your thoughts, ideas, and important information. All your notes are stored locally by default, with optional secure cloud backup. Enjoy a smooth, modern UI with light and dark themes.',
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Main Features:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '''
• Create, edit, and delete notes instantly.
• Organize notes with tags, favorites, and pinning.
• Rich text editing: bold, italic, lists, headings, and more.
• Add images and voice recordings to your notes.
• Secure notes with a password or pattern lock.
• Hide secure notes from the main view for extra privacy (use the secret corner).
• Cloud sync and backup with Google Drive (optional).
• Light and dark themes for comfortable viewing.
• Fast search and filter by tags or favorites.
• Reorder notes with drag-and-drop in both list and grid views.
''',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'How to Use:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '''
• Tap + to create a new note.
• Tap a note to view or edit it.
• Use the heart to favorite, the pin to pin, and the tag bar to filter.
• Tap the three dots (⋮) in a note to access more options: share, delete, add image/audio, or secure the note.
• To secure a note, choose 'Make Secure' and set a password or pattern.
• To view secure notes, tap the secret corner in the home screen (bottom left).
• Use the settings (gear icon) to change theme, enable auto-save, or connect Google Drive for backup.
• Restore your notes from Google Drive at any time from the settings screen.
''',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tips & Privacy:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '''
• All your notes and images are stored locally unless you enable Google Drive sync.
• Secure notes are encrypted and require your password or pattern to unlock.
• You can remove security from a note at any time from the note menu.
• Peteks does not collect or transmit your data unless you use cloud sync.
• For best privacy, use secure notes for sensitive information and enable cloud backup for peace of mind.
''',
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
