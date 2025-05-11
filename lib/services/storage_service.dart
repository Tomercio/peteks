import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class StorageService {
  static const String _notesBoxName = 'notes_box';
  static const String _settingsBoxName = 'settings_box';

  late Box<Note> _notesBox;
  late Box<dynamic> _settingsBox;

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  // Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(NoteAdapter());

    // Define color adapter for Hive
    if (!Hive.isAdapterRegistered(100)) {
      Hive.registerAdapter(ColorAdapter());
    }

    // Open boxes
    _notesBox = await Hive.openBox<Note>(_notesBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
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

  // Search notes by query
  List<Note> searchNotes(String query) {
    if (query.isEmpty) return getAllNotes();

    final lowercaseQuery = query.toLowerCase();
    return _notesBox.values.where((note) {
      return note.title.toLowerCase().contains(lowercaseQuery) ||
          note.content.toLowerCase().contains(lowercaseQuery) ||
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

  // Close boxes when app is shutting down
  Future<void> close() async {
    await _notesBox.close();
    await _settingsBox.close();
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
