import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/note.dart';
import '../../services/storage_service.dart';
import 'note_screen.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Map<DateTime, List<Note>> _notesByDate;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Note> _selectedNotes = [];

  @override
  void initState() {
    super.initState();
    _notesByDate = {};
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotes());
  }

  void _loadNotes() {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final notes = storageService.getAllNotes();
    final Map<DateTime, List<Note>> notesByDate = {};
    for (final note in notes) {
      final date = DateTime(
          note.createdAt.year, note.createdAt.month, note.createdAt.day);
      notesByDate.putIfAbsent(date, () => []).add(note);
    }
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    setState(() {
      _notesByDate = notesByDate;
      _selectedDay = todayKey;
      _selectedNotes = _notesByDate[todayKey] ?? [];
      _focusedDay = todayKey;
    });
  }

  List<Note> _getNotesForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _notesByDate[date] ?? [];
  }

  String _getNotePreview(String content) {
    if (content.isEmpty) return '';
    try {
      final doc = quill.Document.fromJson(jsonDecode(content));
      return doc.toPlainText().trim();
    } catch (e) {
      // fallback for legacy/plain text notes
      return content.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar<Note>(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getNotesForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedNotes = _getNotesForDay(selectedDay);
              });
            },
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedNotes.isEmpty
                ? const Center(child: Text('No notes for this day'))
                : ListView.builder(
                    itemCount: _selectedNotes.length,
                    itemBuilder: (context, index) {
                      final note = _selectedNotes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            note.title.isEmpty ? '(No Title)' : note.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            _getNotePreview(note.content),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => NoteScreen(note: note)),
                            );
                            if (!mounted) return;
                            _loadNotes();
                          },
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
