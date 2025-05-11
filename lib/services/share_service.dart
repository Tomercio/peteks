import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  /// Share note as plain text
  Future<void> shareAsText(Note note) async {
    final text = _formatNoteAsText(note);
    await Share.share(text, subject: note.title);
  }

  /// Share note as markdown
  Future<void> shareAsMarkdown(Note note) async {
    final markdown = _formatNoteAsMarkdown(note);
    await Share.share(markdown, subject: '${note.title}.md');
  }

  /// Share note as a file (including images)
  Future<void> shareAsFile(Note note) async {
    // Create a temporary directory
    final tempDir = await getTemporaryDirectory();
    final noteDir = Directory(path.join(tempDir.path, 'note_${note.id}'));
    await noteDir.create(recursive: true);

    // Create the note file
    final noteFile = File(path.join(noteDir.path, '${note.title}.md'));
    await noteFile.writeAsString(_formatNoteAsMarkdown(note));

    // Copy images if any
    final List<XFile> files = [XFile(noteFile.path)];
    for (final imagePath in note.imagePaths) {
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        final newPath = path.join(noteDir.path, path.basename(imagePath));
        await imageFile.copy(newPath);
        files.add(XFile(newPath));
      }
    }

    // Share the files
    await Share.shareXFiles(
      files,
      subject: note.title,
      text: 'Note from Peteks',
    );

    // Clean up temporary directory
    await noteDir.delete(recursive: true);
  }

  String _extractPlainText(String content) {
    if (content.isEmpty) return '';
    try {
      final dynamic decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded
            .map((op) => op['insert'])
            .whereType<String>()
            .join()
            .replaceAll('\n', ' ')
            .trim();
      }
    } catch (e) {
      // If not JSON, treat as plain text
    }
    return content.trim();
  }

  String _formatNoteAsText(Note note) {
    final buffer = StringBuffer();

    // Add title
    if (note.title.isNotEmpty) {
      buffer.writeln(note.title);
      buffer.writeln();
    }

    // Add content (as plain text)
    final plainContent = _extractPlainText(note.content);
    if (plainContent.isNotEmpty) {
      buffer.writeln(plainContent);
      buffer.writeln();
    }

    // Add tags
    if (note.tags.isNotEmpty) {
      buffer.writeln('Tags: ${note.tags.join(", ")}');
      buffer.writeln();
    }

    // Add date
    buffer.writeln('Created: ${note.createdAt}');
    buffer.writeln('Modified: ${note.modifiedAt}');

    return buffer.toString();
  }

  String _formatNoteAsMarkdown(Note note) {
    final buffer = StringBuffer();

    // Add title
    if (note.title.isNotEmpty) {
      buffer.writeln('# ${note.title}');
      buffer.writeln();
    }

    // Add content (as plain text)
    final plainContent = _extractPlainText(note.content);
    if (plainContent.isNotEmpty) {
      buffer.writeln(plainContent);
      buffer.writeln();
    }

    // Add tags
    if (note.tags.isNotEmpty) {
      buffer.writeln('Tags: ${note.tags.map((tag) => "#$tag").join(" ")}');
      buffer.writeln();
    }

    // Add metadata
    buffer.writeln('---');
    buffer.writeln('Created: ${note.createdAt}');
    buffer.writeln('Modified: ${note.modifiedAt}');
    if (note.reminderDateTime != null) {
      buffer.writeln('Reminder: ${note.reminderDateTime}');
    }

    return buffer.toString();
  }
}
