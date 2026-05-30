import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coral = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? Colors.white54 : Colors.black45;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Peteks'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo + tagline
            Center(
              child: Column(
                children: [
                  Image.asset('assets/peteks.png', height: 80),
                  const SizedBox(height: 10),
                  Text(
                    'Peteks',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: coral,
                        fontFamily: 'Nunito'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your notes, beautifully and private.',
                    style: TextStyle(
                        fontSize: 13,
                        color: mutedColor,
                        fontFamily: 'Nunito'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _Section(
              icon: Icons.edit_note_rounded,
              title: 'Creating & Editing Notes',
              color: coral,
              items: [
                'Tap ＋ (bottom right) to create a new note.',
                'Tap any note to open and edit it.',
                'Use the toolbar inside a note for bold, italic, headings, lists, and more.',
                'Tap ⋮ (top right in a note) for more options: share, add image, add voice memo, or secure the note.',
                'Notes auto-save as you type — no need to press Save.',
              ],
            ),

            _Section(
              icon: Icons.folder_outlined,
              title: 'Folders',
              color: coral,
              items: [
                'Tap 📁 (the folder icon at the top) to create a new folder.',
                'Tap a folder chip to filter notes by that folder.',
                'Tap "All" to go back to seeing all your notes.',
                'Long-press any note → "Move to Folder" to move it to any folder.',
                'Long-press a note → "Move to Folder" → "All Notes" to remove it from a folder.',
              ],
            ),

            _Section(
              icon: Icons.label_outline,
              title: 'Tags & Filtering',
              color: coral,
              items: [
                'Add tags inside a note from the tag field at the bottom.',
                'Use the tag bar (below folders) to filter by tag.',
                'Tap "All" in the tag bar to clear the tag filter.',
                'Tap ♡ to filter by favorites only.',
                'Notes can have multiple tags.',
              ],
            ),

            _Section(
              icon: Icons.lock_outline,
              title: 'Secure Notes',
              color: coral,
              items: [
                'Open a note → tap ⋮ → "Make Secure" to lock it with a password or pattern.',
                'Secure notes are hidden from the main list by default for extra privacy.',
                'To view secure notes: tap the secret corner in the bottom-left of the home screen.',
                'Each secure note has its own individual lock — no shared master password.',
                'Passwords are never stored in plain text (HMAC-SHA256 hashing).',
                'To remove security: open the note → tap ⋮ → "Remove Security".',
              ],
            ),

            _Section(
              icon: Icons.touch_app_outlined,
              title: 'Long Press Actions',
              color: coral,
              items: [
                'Long-press any note card to open a quick-action menu.',
                '"Move to Folder" — assign the note to a folder or remove it from one.',
                '"Delete" — deletes the note (with a 4-second Undo option).',
              ],
            ),

            _Section(
              icon: Icons.cloud_outlined,
              title: 'Google Drive Sync',
              color: coral,
              items: [
                'Go to Settings → Google Drive Backup to connect your Google account.',
                'Tap "Backup Now" to save all your notes to your personal Google Drive.',
                'Tap "Restore" to load your notes back from your Drive backup.',
                'Your backup goes to YOUR Drive — Peteks cannot access it.',
                'Sync is manual — tap backup whenever you want to save.',
              ],
            ),

            _Section(
              icon: Icons.image_outlined,
              title: 'Images & Voice Memos',
              color: coral,
              items: [
                'Inside a note, tap ⋮ → "Add Image" to attach a photo from gallery or camera.',
                'Tap ⋮ → "Record Voice Note" to attach an audio memo.',
                'Images and audio are stored locally on your device only.',
              ],
            ),

            _Section(
              icon: Icons.push_pin_outlined,
              title: 'Pinning & Favorites',
              color: coral,
              items: [
                'Pin a note to keep it at the top of your list.',
                'Favorite a note (♡) to quickly find it later using the favorites filter.',
                'Drag and drop notes (in grid or list view) to reorder them manually.',
              ],
            ),

            _Section(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy',
              color: coral,
              items: [
                'All notes stay on your device — never sent to our servers.',
                'Only anonymous crash reports (Firebase) leave your device.',
                'No ads, no tracking, no data selling — ever.',
                'Contact: info@peteksapp.com',
              ],
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: mutedColor, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<String> items;

  const _Section({
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                          fontSize: 13,
                          height: 1.55,
                          fontFamily: 'Nunito'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
