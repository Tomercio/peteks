import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart'; // Import ThemeService from main
import 'package:package_info_plus/package_info_plus.dart';
import '../widgets/store_badges.dart';
import '../../services/google_drive_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/storage_service.dart';
import 'dart:convert';
import '../../models/note.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  bool _nicknameChanged = false; // Track if nickname changed

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    _loadVersion();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _promptForNicknameIfNeeded());
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
    });
  }

  Future<void> _promptForNicknameIfNeeded() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final nickname = storageService.getNickname();
    if (nickname == null || nickname.trim().isEmpty) {
      final controller = TextEditingController();
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('What is your nickname?'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter your nickname'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  storageService.setNickname(controller.text.trim());
                  _nicknameChanged = true; // Mark as changed
                  Navigator.of(context).pop(); // Only close dialog
                  setState(() {}); // Optionally update settings UI
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final storageService = Provider.of<StorageService>(context, listen: false);
    bool autoSave =
        storageService.getSetting('autoSave', defaultValue: false) == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _nicknameChanged),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
      ),
      body: ListView(
        children: [
          // App Theme Section
          _buildSectionHeader(context, 'Appearance'),

          ListTile(
            leading: const Icon(Icons.light_mode),
            title: const Text('Comfy Light'),
            trailing: themeService.isLightMode
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: themeService.setLight,
          ),

          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Comfy Dark'),
            trailing: themeService.isDarkMode
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: themeService.setDark,
          ),

          ListTile(
            leading: const Icon(Icons.settings_suggest),
            title: const Text('System Default'),
            trailing: themeService.isSystemMode
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: themeService.setSystem,
          ),

          SwitchListTile(
            title: const Text('Auto Save Notes'),
            subtitle: const Text('Automatically save notes as you type'),
            value: autoSave,
            onChanged: (value) {
              storageService.saveSetting('autoSave', value);
              setState(() {});
            },
          ),

          const Divider(),

          // Google Drive Sync Section
          _buildSectionHeader(context, 'Cloud Sync'),
          _GoogleDriveSyncSection(),

          const Divider(),

          // About Section
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: Text(_version),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Peteks',
                applicationVersion: _version,
                applicationIcon: const FlutterLogo(size: 64),
                children: [
                  const Text(
                    'Peteks is a simple and elegant note-taking app that helps you organize your thoughts and ideas.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Download Peteks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const StoreBadges(height: 48),
                ],
              );
            },
          ),

          ListTile(
            title: const Text('Privacy Policy'),
            leading: const Icon(Icons.privacy_tip_outlined),
            onTap: () {
              Navigator.pushNamed(context, '/privacy');
            },
          ),
          ListTile(
            title: const Text('Terms of Service'),
            leading: const Icon(Icons.description_outlined),
            onTap: () {
              Navigator.pushNamed(context, '/terms');
            },
          ),
          ListTile(
            title: const Text('Rate the App'),
            leading: const Icon(Icons.star_outline),
            onTap: () {
              // Open app store rating page
              final packageName =
                  'com.peteks.app'; // Replace with your actual package name
              final url = Uri.parse(
                'market://details?id=$packageName',
              );
              launchUrl(url, mode: LaunchMode.externalApplication);
            },
          ),
          ListTile(
            title: const Text('Share the App'),
            leading: const Icon(Icons.share_outlined),
            onTap: () {
              final packageName =
                  'com.peteks.app'; // Replace with your actual package name
              final url = Uri.parse(
                'https://play.google.com/store/apps/details?id=$packageName',
              );
              Share.share(
                'Check out Peteks - A beautiful note-taking app!\n$url',
                subject: 'Peteks - Note Taking App',
              );
            },
          ),
          const SizedBox(height: 32),
          Center(
            child: Image.asset(
              'assets/peteks.png',
              height: 96,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _GoogleDriveSyncSection extends StatefulWidget {
  @override
  State<_GoogleDriveSyncSection> createState() =>
      _GoogleDriveSyncSectionState();
}

class _GoogleDriveSyncSectionState extends State<_GoogleDriveSyncSection> {
  bool _isSignedIn = false;
  bool _isLoading = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _checkSignIn();
  }

  Future<void> _checkSignIn() async {
    setState(() => _isLoading = true);
    try {
      final service = GoogleDriveService();
      final folderId = await service.getOrCreateNotesFolder();
      setState(() => _isSignedIn = folderId != null);
    } catch (_) {
      setState(() => _isSignedIn = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    final service = GoogleDriveService();
    final ok = await service.signIn();
    setState(() {
      _isSignedIn = ok;
      _status = ok ? 'Signed in!' : 'Sign-in failed.';
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    final service = GoogleDriveService();
    await service.signOut();
    setState(() {
      _isSignedIn = false;
      _status = 'Signed out.';
      _isLoading = false;
    });
  }

  Future<void> _syncToDrive() async {
    setState(() {
      _isLoading = true;
      _status = null;
    });
    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final notes = storageService.getAllNotes();
      final driveService = GoogleDriveService();
      // Upload all images and audio files
      for (final note in notes) {
        for (final imagePath in note.imagePaths) {
          final file = File(imagePath);
          if (file.existsSync()) {
            final bytes = await file.readAsBytes();
            await driveService.uploadImage(file.uri.pathSegments.last, bytes);
          }
        }
        if (note.audioPath != null && note.audioPath!.isNotEmpty) {
          final audioFile = File(note.audioPath!);
          if (audioFile.existsSync()) {
            final bytes = await audioFile.readAsBytes();
            await driveService.uploadImage(
                audioFile.uri.pathSegments.last, bytes);
          }
        }
      }
      // Export all notes as JSON
      final notesJson = notes.map((n) => n.toJson()).toList();
      final jsonString = jsonEncode(notesJson);
      await driveService.uploadNoteMd('peteks_notes_backup.json', jsonString);
      setState(() => _status = 'Sync complete!');
    } catch (e) {
      setState(() => _status = 'Sync failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreFromDrive() async {
    setState(() {
      _isLoading = true;
      _status = null;
    });
    try {
      final driveService = GoogleDriveService();
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final notesMd = await driveService.downloadAllNotesMd();
      final images = await driveService.downloadAllImages();
      // Save images/audio to local directory and build a map of fileName -> localPath
      final dir = await getApplicationDocumentsDirectory();
      final Map<String, String> fileMap = {};
      for (final img in images) {
        final fileName = img['fileName'] as String;
        final bytes = img['bytes'] as List<int>;
        final localPath = '${dir.path}/$fileName';
        final file = File(localPath);
        await file.writeAsBytes(bytes, flush: true);
        fileMap[fileName] = localPath;
      }
      // Find the backup file
      final backup = notesMd.firstWhere(
        (n) => n['fileName'] == 'peteks_notes_backup.json',
        orElse: () => {},
      );
      if (backup.isEmpty || backup['content'] == null) {
        setState(() => _status = 'No backup found in Drive.');
      } else {
        final List<dynamic> notesJson = jsonDecode(backup['content']!);
        for (final noteMap in notesJson) {
          final noteData = Map<String, dynamic>.from(noteMap);
          // Update imagePaths and audioPath to new local files if present
          if (noteData['imagePaths'] != null) {
            noteData['imagePaths'] =
                List<String>.from(noteData['imagePaths']).map((p) {
              final fileName = p.split(Platform.pathSeparator).last;
              return fileMap[fileName] ?? p;
            }).toList();
          }
          if (noteData['audioPath'] != null &&
              noteData['audioPath'].isNotEmpty) {
            final fileName =
                noteData['audioPath'].split(Platform.pathSeparator).last;
            noteData['audioPath'] = fileMap[fileName] ?? noteData['audioPath'];
          }
          final note = Note.fromJson(noteData);
          await storageService.saveNote(note);
        }
        setState(() => _status = 'Restore complete!');
      }
    } catch (e) {
      setState(() => _status = 'Restore failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(_isSignedIn ? Icons.cloud_done : Icons.cloud_off),
          title: Text(_isSignedIn
              ? 'Signed in to Google Drive'
              : 'Sign in with Google'),
          subtitle: _status != null ? Text(_status!) : null,
          trailing: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : _isSignedIn
                  ? TextButton(
                      onPressed: _signOut, child: const Text('Sign out'))
                  : TextButton(
                      onPressed: _signIn, child: const Text('Sign in')),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_upload),
          title: const Text('Sync to Google Drive'),
          enabled: _isSignedIn && !_isLoading,
          onTap: _isSignedIn ? _syncToDrive : null,
        ),
        ListTile(
          leading: const Icon(Icons.cloud_download),
          title: const Text('Restore from Google Drive'),
          enabled: _isSignedIn && !_isLoading,
          onTap: _isSignedIn ? _restoreFromDrive : null,
        ),
      ],
    );
  }
}
