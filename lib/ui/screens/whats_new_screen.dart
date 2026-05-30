import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';

/// Release notes keyed by version string.
const Map<String, List<String>> _releaseNotes = {
  '1.0.0': [
    'Rich text editor with checklists, bold, italic, and more',
    'Comfy Light & Comfy Dark themes',
    'Secure notes with pattern or password lock',
    'Folders & categories system',
    'Google Drive backup & restore',
    'Auto-save with debounce',
    'Undo note deletion',
    'Sort notes by date, title, or modified time',
    'Onboarding flow for new users',
    'RTL / Hebrew content support',
  ],
};

class WhatsNewDialog extends StatelessWidget {
  final String version;
  const WhatsNewDialog({super.key, required this.version});

  static Future<void> showIfNeeded(BuildContext context) async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final info = await PackageInfo.fromPlatform();
    final current = info.version;
    final stored = storage.getSetting('lastSeenVersion', defaultValue: '');
    if (stored == current) return;
    await storage.saveSetting('lastSeenVersion', current);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (_) => WhatsNewDialog(version: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = _releaseNotes[version] ?? _releaseNotes.values.last;
    final primary = Theme.of(context).colorScheme.primary;
    return AlertDialog(
      title: Text(
        "What's new in v$version",
        style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: notes
              .map((note) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 16, color: primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note,
                            style: const TextStyle(
                                fontFamily: 'Nunito', fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Let's go!"),
        ),
      ],
    );
  }
}
