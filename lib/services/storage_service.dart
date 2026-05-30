import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import '../models/folder.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

class StorageService extends ChangeNotifier {
  static const String _notesBoxName = 'notes_box';
  static const String _settingsBoxName = 'settings_box';
  static const String _foldersBoxName = 'folders_box';

  late Box<Note> _notesBox;
  late Box<dynamic> _settingsBox;
  late Box<Folder> _foldersBox;

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  String? _nickname;

  // Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(NoteAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(FolderAdapter());
    }

    // Define color adapter for Hive
    if (!Hive.isAdapterRegistered(100)) {
      Hive.registerAdapter(ColorAdapter());
    }

    // Open boxes
    _notesBox = await Hive.openBox<Note>(_notesBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _foldersBox = await Hive.openBox<Folder>(_foldersBoxName);

    // Load nickname from storage
    _nickname = _settingsBox.get('nickname');
  }

  // CRUD Operations for Notes

  // Create or update a note
  Future<void> saveNote(Note note) async {
    await _notesBox.put(note.id, note);
  }

  // Get a note by id
  Note? getNote(String id) {
    return _notesBox.get(id);
  }

  // Get all notes
  List<Note> getAllNotes() {
    return _notesBox.values.toList();
  }

  // Delete a note
  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }

  // Extract plain text from Quill Delta JSON for searching.
  static String _extractPlainText(String content) {
    if (content.isEmpty) return '';
    try {
      final delta = jsonDecode(content) as List<dynamic>;
      final buffer = StringBuffer();
      for (final op in delta) {
        if (op is Map && op['insert'] is String) {
          buffer.write(op['insert']);
        }
      }
      return buffer.toString();
    } catch (_) {
      return content;
    }
  }

  // Search notes by query — searches title, plain-text content, and tags.
  List<Note> searchNotes(String query) {
    if (query.isEmpty) return getAllNotes();

    final lowercaseQuery = query.toLowerCase();
    return _notesBox.values.where((note) {
      final plainText = _extractPlainText(note.content).toLowerCase();
      return note.title.toLowerCase().contains(lowercaseQuery) ||
          plainText.contains(lowercaseQuery) ||
          note.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Get notes filtered by tag
  List<Note> getNotesByTag(String tag) {
    return _notesBox.values.where((note) => note.tags.contains(tag)).toList();
  }

  // Get favorite notes
  List<Note> getFavoriteNotes() {
    return _notesBox.values.where((note) => note.isFavorite).toList();
  }

  // Get all tags across all notes
  List<String> getAllTags() {
    final Set<String> tags = {};
    for (final note in _notesBox.values) {
      tags.addAll(note.tags);
    }
    return tags.toList();
  }

  // Settings operations

  // Save a setting
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  // Get a setting
  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  // Nickname operations
  void setNickname(String nickname) {
    _nickname = nickname;
    _settingsBox.put('nickname', nickname);
    notifyListeners();
  }

  String? getNickname() {
    _nickname ??= _settingsBox.get('nickname');
    return _nickname;
  }

  // Folder operations

  List<Folder> getFolders() {
    final folders = _foldersBox.values.toList();
    folders.sort((a, b) => a.position.compareTo(b.position));
    return folders;
  }

  Future<void> saveFolder(Folder folder) async {
    await _foldersBox.put(folder.id, folder);
    notifyListeners();
  }

  Future<void> deleteFolder(String folderId) async {
    await _foldersBox.delete(folderId);
    // Move notes in this folder to "All Notes"
    final notesInFolder =
        _notesBox.values.where((n) => n.folderId == folderId).toList();
    for (final note in notesInFolder) {
      await _notesBox.put(note.id, note.copyWith(folderId: null));
    }
    notifyListeners();
  }

  List<Note> getNotesByFolder(String? folderId) {
    if (folderId == null) return getAllNotes();
    return _notesBox.values.where((n) => n.folderId == folderId).toList();
  }

  // Close boxes when app is shutting down
  Future<void> close() async {
    await _notesBox.close();
    await _settingsBox.close();
    await _foldersBox.close();
  }
}

// Custom adapter for Color class
class ColorAdapter extends TypeAdapter<Color> {
  @override
  final int typeId = 100;

  @override
  Color read(BinaryReader reader) {
    return Color(reader.readInt());
  }

  @override
  void write(BinaryWriter writer, Color obj) {
    writer.writeInt(obj.toARGB32());
  }
}
