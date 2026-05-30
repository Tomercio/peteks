import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../widgets/note_card.dart';
import '../../services/storage_service.dart';
import '../../models/note.dart';
import '../../main.dart';
import 'note_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:pattern_lock/pattern_lock.dart';
import 'calendar_screen.dart';
import '../../services/image_service.dart';
import '../../models/folder.dart';
import '../../utils/pending_delete.dart';
import 'whats_new_screen.dart';

// Verify a security input against the stored hash.
// Supports both new HMAC+salt hashes and legacy plain-sha256 hashes.
bool _verifyHash(String input, String storedHash, String? salt) {
  if (salt != null && salt.isNotEmpty) {
    final key = utf8.encode(salt);
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(input)).toString() == storedHash;
  }
  // Legacy fallback: plain sha256
  return sha256.convert(utf8.encode(input)).toString() == storedHash;
}

enum ViewMode { grid, list }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late StorageService _storageService;
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  String? _selectedTag;
  bool _showOnlyFavorites = false;
  bool _showOnlySecured = false;
  String? _selectedFolderId; // null = All Notes
  String _sortMode = 'modified'; // modified | created | az | za

  // Add view mode state
  ViewMode _viewMode = ViewMode.list;

  bool _showSecureHint = false;

  // Animation for tags
  late AnimationController _tagController;
  late Animation<double> _tagAnimation;
  late AnimationController _hintPulseController;
  late Animation<double> _hintPulse;

  // Animation for greeting pop
  late AnimationController _greetingController;
  late Animation<double> _greetingFade;
  late Animation<Offset> _greetingSlide;

  @override
  void initState() {
    super.initState();

    // Initialize tag animation controller
    _tagController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tagAnimation = CurvedAnimation(
      parent: _tagController,
      curve: Curves.easeInOut,
    );

    // Greeting welcoming animation
    _greetingController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _greetingFade = CurvedAnimation(
      parent: _greetingController,
      curve: Curves.easeInOut,
    );
    _greetingSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _greetingController,
      curve: Curves.easeOutCubic,
    ));

    _hintPulseController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _hintPulse = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _hintPulseController, curve: Curves.easeInOut),
    );

    // Load view preference from settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadViewPreference();
      _tagController.forward();
    });
  }

  @override
  void dispose() {
    _tagController.dispose();
    _greetingController.dispose();
    _hintPulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storageService = Provider.of<StorageService>(context);
    _loadNotes();
    _greetingController.forward(from: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WhatsNewDialog.showIfNeeded(context);
    });
  }

  void _loadViewPreference() {
    final savedViewMode =
        _storageService.getSetting('viewMode', defaultValue: 'list');
    final savedSort =
        _storageService.getSetting('sortMode', defaultValue: 'modified');
    setState(() {
      _viewMode = savedViewMode == 'grid' ? ViewMode.grid : ViewMode.list;
      _sortMode = savedSort as String;
    });
  }

  void _saveViewPreference(ViewMode mode) {
    final modeString = mode == ViewMode.list ? 'list' : 'grid';
    _storageService.saveSetting('viewMode', modeString);
  }

  void _toggleViewMode() {
    final newMode = _viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
    setState(() {
      _viewMode = newMode;
    });
    _saveViewPreference(newMode);
  }

  void _loadNotes() {
    setState(() {
      _notes = _storageService.getAllNotes();
      _applyFilters();
    });
    _checkSecureHint();
  }

  void _checkSecureHint() {
    final hasSecure = _notes.any((n) => n.isSecure);
    final hasSeen =
        _storageService.getSetting('hasSeenSecureHint', defaultValue: false) == true;
    if (hasSecure && !hasSeen && mounted) {
      setState(() => _showSecureHint = true);
    }
  }

  void _dismissSecureHint() {
    _storageService.saveSetting('hasSeenSecureHint', true);
    setState(() => _showSecureHint = false);
  }

  void _applyFilters() {
    setState(() {
      _filteredNotes = List.from(_notes);
      if (_selectedFolderId != null) {
        _filteredNotes = _filteredNotes
            .where((note) => note.folderId == _selectedFolderId)
            .toList();
      }
      if (_selectedTag != null) {
        _filteredNotes = _filteredNotes
            .where((note) => note.tags.contains(_selectedTag))
            .toList();
      }
      if (_showOnlyFavorites) {
        _filteredNotes =
            _filteredNotes.where((note) => note.isFavorite).toList();
      }
      // Only show secure notes if the secret filter is active
      if (_showOnlySecured) {
        _filteredNotes = _filteredNotes.where((note) => note.isSecure).toList();
      } else {
        _filteredNotes =
            _filteredNotes.where((note) => !note.isSecure).toList();
      }
      _filteredNotes.sort((a, b) {
        // Pinned always first
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        switch (_sortMode) {
          case 'created':
            return b.createdAt.compareTo(a.createdAt);
          case 'az':
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          case 'za':
            return b.title.toLowerCase().compareTo(a.title.toLowerCase());
          case 'modified':
          default:
            if (a.position != b.position) {
              return a.position.compareTo(b.position);
            }
            return b.modifiedAt.compareTo(a.modifiedAt);
        }
      });
    });
  }

  void _toggleFavoritesFilter() {
    setState(() {
      _showOnlyFavorites = !_showOnlyFavorites;
      _applyFilters();
    });
  }

  void _selectTag(String? tag) {
    setState(() {
      _selectedTag = tag;
      _applyFilters();
      _tagController.reset();
      _tagController.forward();
    });
  }

  void _createNewNote() async {
    // Find the next position
    int maxPosition = _notes.isEmpty
        ? 0
        : _notes.map((n) => n.position).reduce((a, b) => a > b ? a : b) + 1;

    // Create note in memory only — do NOT save until user adds a title
    final note = Note(
      title: '',
      content: '',
      position: maxPosition,
    );

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => NoteScreen(note: note, isNew: true)),
      );
      if (!mounted) return;
      setState(() => _loadNotes());
    }
  }

  /// After any delete, check if we're in secure view with no secured notes left → go back to normal.
  void _exitSecureViewIfEmpty() {
    if (_showOnlySecured && !_notes.any((n) => n.isSecure)) {
      setState(() {
        _showOnlySecured = false;
        _applyFilters();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more secured notes — back to regular view.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Delete a note immediately from both the list and storage.
  Future<void> _deleteNoteInstantly(Note note) async {
    setState(() {
      _notes.removeWhere((n) => n.id == note.id);
      _filteredNotes.removeWhere((n) => n.id == note.id);
    });
    _exitSecureViewIfEmpty();
    await _storageService.deleteNote(note.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showLongPressMenu(Note note) {
    final folders = _storageService.getFolders();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                note.title.isEmpty ? 'Untitled' : note.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    fontFamily: 'Nunito'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(),
            // Move to folder
            ListTile(
              leading: const Icon(Icons.drive_file_move_outline),
              title: const Text('Move to Folder',
                  style: TextStyle(fontFamily: 'Nunito')),
              onTap: () {
                Navigator.of(ctx).pop();
                _showMoveFolderDialog(note, folders);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete',
                  style: TextStyle(color: Colors.red, fontFamily: 'Nunito')),
              onTap: () {
                Navigator.of(ctx).pop();
                _deleteNoteInstantly(note);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showMoveFolderDialog(Note note, List<Folder> folders) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Move to Folder',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    fontFamily: 'Nunito'),
              ),
            ),
            const Divider(),
            // "No folder" option
            ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: const Text('All Notes (remove from folder)',
                  style: TextStyle(fontFamily: 'Nunito')),
              trailing: note.folderId == null
                  ? const Icon(Icons.check, size: 18)
                  : null,
              onTap: () async {
                Navigator.of(ctx).pop();
                final updated = note.copyWith(folderId: null, clearFolderId: true);
                await _storageService.saveNote(updated);
                setState(() => _loadNotes());
              },
            ),
            ...folders.map((folder) => ListTile(
                  leading: Icon(folder.icon, color: folder.color),
                  title: Text(folder.name,
                      style: const TextStyle(fontFamily: 'Nunito')),
                  trailing: note.folderId == folder.id
                      ? const Icon(Icons.check, size: 18)
                      : null,
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final updated = note.copyWith(folderId: folder.id);
                    await _storageService.saveNote(updated);
                    setState(() => _loadNotes());
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePendingDelete(String noteId) async {
    // Remove from the visible list immediately — no refresh lag
    setState(() {
      _notes.removeWhere((n) => n.id == noteId);
      _filteredNotes.removeWhere((n) => n.id == noteId);
    });
    _exitSecureViewIfEmpty();

    bool undone = false;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: const Text('Note deleted'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            undone = true;
            PendingDelete.clear();
            setState(() => _loadNotes()); // restore from storage
          },
        ),
      ),
    );
    await controller.closed;
    if (!undone) {
      final pending = PendingDelete.note;
      if (pending != null && pending.id == noteId) {
        for (final p in PendingDelete.imagePaths) {
          await ImageService.deleteImage(p);
        }
        await _storageService.deleteNote(noteId);
        PendingDelete.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final nickname = storageService.getNickname();
    String? greeting;
    if (nickname != null && nickname.trim().isNotEmpty) {
      final hour = DateTime.now().hour;
      if (hour < 5 || hour >= 22) {
        greeting = 'Good night, $nickname! 😴';
      } else if (hour < 12) {
        greeting = 'Good morning, $nickname! 🌞';
      } else if (hour < 19) {
        greeting = 'Good afternoon, $nickname! 🌞';
      } else {
        greeting = 'Good evening, $nickname! 🌙';
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/peteks.png',
          height: 65,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, size: 20),
            tooltip: 'Sort notes',
            padding: EdgeInsets.zero,
            onSelected: (value) {
              setState(() {
                _sortMode = value;
                _storageService.saveSetting('sortMode', value);
                _applyFilters();
              });
            },
            itemBuilder: (_) => [
              _sortItem('modified', 'Last modified', Icons.access_time),
              _sortItem('created', 'Date created', Icons.calendar_today_outlined),
              _sortItem('az', 'A → Z', Icons.sort_by_alpha),
              _sortItem('za', 'Z → A', Icons.sort_by_alpha),
            ],
          ),
          IconButton(
            icon: Icon(
                _viewMode == ViewMode.grid ? Icons.view_list : Icons.grid_view,
                size: 20),
            onPressed: _toggleViewMode,
            tooltip: _viewMode == ViewMode.grid ? 'List view' : 'Grid view',
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(width: 4),
          IconButton(
            icon: Icon(
                _showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
                size: 20),
            onPressed: _toggleFavoritesFilter,
            tooltip: 'Show favorites',
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
            },
            tooltip: 'Calendar',
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.search, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            onPressed: () async {
              final themeService =
                  Provider.of<ThemeService>(context, listen: false);
              final result = await Navigator.of(context).push(
                slideRoute(
                  ChangeNotifierProvider.value(
                    value: themeService,
                    child: const SettingsScreen(),
                  ),
                ),
              );
              if (result == true) {
                setState(() {
                  _loadNotes();
                });
              }
            },
            tooltip: 'Settings',
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),

      // Tags bar
      body: Stack(
        children: [
          Column(
            children: [
              if (greeting != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(top: 16, left: 20, bottom: 8),
                    child: FadeTransition(
                      opacity: _greetingFade,
                      child: SlideTransition(
                        position: _greetingSlide,
                        child: Text(
                          greeting,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? const Color(0xFF7C6F62)
                                    : const Color(0xFFF4ECD9),
                            fontFamily: 'Nunito',
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                  ),
                ),
              _buildFolderBar(),
              if (_notes.isNotEmpty) _buildTagsBar(),

              // Notes display - Grid or List
              Expanded(
                child: _filteredNotes.isEmpty
                    ? _buildEmptyState()
                    : (_viewMode == ViewMode.list
                        ? _buildListView()
                        : _buildGridView()),
              ),
            ],
          ),
          // Secret button in bottom-left (only if there is a secure note or the filter is active)
          if (_notes.any((n) => n.isSecure) || _showOnlySecured)
            Positioned(
              left: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  if (_showSecureHint) _dismissSecureHint();
                  setState(() {
                    _showOnlySecured = !_showOnlySecured;
                    _applyFilters();
                  });
                },
                child: CustomPaint(
                  size: const Size(28, 28),
                  painter: _FoldedCornerButtonPainter(),
                ),
              ),
            ),

          // One-time hint pointing to the secret corner button
          if (_showSecureHint)
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismissSecureHint,
                child: Container(
                  color: Colors.black.withAlpha(140),
                  child: Stack(
                    children: [
                      // Arrow + label pointing to bottom-left corner
                      Positioned(
                        left: 16,
                        bottom: 52,
                        child: AnimatedBuilder(
                          animation: _hintPulse,
                          builder: (context, child) => Opacity(
                            opacity: _hintPulse.value,
                            child: child,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Text(
                                  '🔒  Your secured notes are hidden here!\nTap this corner to reveal them.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              // Arrow pointing down-left toward the corner
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: CustomPaint(
                                  size: const Size(20, 16),
                                  painter: _DownArrowPainter(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // "Tap anywhere to dismiss" hint at center-bottom
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            'Tap anywhere to dismiss',
                            style: TextStyle(
                              color: Colors.white.withAlpha(160),
                              fontSize: 12,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Main add note button
          FloatingActionButton(
            onPressed: _createNewNote,
            tooltip: 'Add new note',
            heroTag: 'add_note',
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ReorderableListView.builder(
      key: const ValueKey('list_view'),
      padding: const EdgeInsets.all(8),
      itemCount: _filteredNotes.length,
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        return Material(
          color: Colors.transparent,
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final note = _filteredNotes.removeAt(oldIndex);
          _filteredNotes.insert(newIndex, note);
          for (int i = 0; i < _filteredNotes.length; i++) {
            final updatedNote = _filteredNotes[i].copyWith(position: i);
            _storageService.saveNote(updatedNote);
          }
        });
      },
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return NoteCard(
          key: ValueKey(note.id),
          note: note,
          onTap: () async {
            bool unlocked = true;
            if (note.isSecure) {
              unlocked = false;
              if (note.securityType == 'password') {
                unlocked = await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        final TextEditingController pass =
                            TextEditingController();
                        return AlertDialog(
                          title: const Text('Enter Password'),
                          content: TextField(
                            controller: pass,
                            obscureText: true,
                            decoration:
                                const InputDecoration(labelText: 'Password'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                if (_verifyHash(pass.text, note.securityHash!, note.securitySalt)) {
                                  Navigator.of(context).pop(true);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Incorrect password')),
                                  );
                                }
                              },
                              child: const Text('Unlock'),
                            ),
                          ],
                        );
                      },
                    ) ??
                    false;
              } else if (note.securityType == 'pattern') {
                unlocked = await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Enter Pattern'),
                          content: SizedBox(
                            width: 250,
                            height: 300,
                            child: PatternLock(
                              selectedColor:
                                  Theme.of(context).colorScheme.primary,
                              notSelectedColor: Colors.grey,
                              pointRadius: 10,
                              showInput: true,
                              dimension: 3,
                              onInputComplete: (List<int> input) {
                                if (_verifyHash(input.join('-'), note.securityHash!, note.securitySalt)) {
                                  Navigator.of(context).pop(true);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Incorrect pattern')),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ) ??
                    false;
              }
            }
            if (!unlocked) return;
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NoteScreen(note: note)),
            );
            if (!mounted) return;
            if (result is Map && result['pendingDelete'] != null) {
              _handlePendingDelete(result['pendingDelete'] as String);
            } else {
              setState(() => _loadNotes());
            }
          },
          onLongPress: () => _showLongPressMenu(note),
          onFavoriteToggle: () {
            setState(() {
              final updatedNote = note.copyWith(
                isFavorite: !note.isFavorite,
              );
              _storageService.saveNote(updatedNote);
              _loadNotes();
            });
          },
          mode: NoteCardMode.list,
        );
      },
    );
  }

  Widget _buildGridView() {
    return ReorderableGridView.builder(
      key: const ValueKey('grid_view'),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      dragWidgetBuilder: (index, child) {
        return Material(
          color: Colors.transparent,
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
          child: child,
        );
      },
      itemCount: _filteredNotes.length,
      onReorder: (oldIndex, newIndex) {
        if (oldIndex == newIndex) return;

        setState(() {
          // Create a copy of the list
          final List<Note> newList = List.from(_filteredNotes);

          // Remove the item from the old position
          final Note item = newList.removeAt(oldIndex);

          // Insert the item at the new position
          newList.insert(newIndex, item);

          // Update the filtered notes
          _filteredNotes = newList;

          // Update positions for all notes
          for (int i = 0; i < _filteredNotes.length; i++) {
            final updatedNote = _filteredNotes[i].copyWith(position: i);
            _storageService.saveNote(updatedNote);
          }
        });
      },
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return NoteCard(
          key: ValueKey(note.id),
          note: note,
          onTap: () async {
            bool unlocked = true;
            if (note.isSecure) {
              unlocked = false;
              if (note.securityType == 'password') {
                unlocked = await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        final TextEditingController pass =
                            TextEditingController();
                        return AlertDialog(
                          title: const Text('Enter Password'),
                          content: TextField(
                            controller: pass,
                            obscureText: true,
                            decoration:
                                const InputDecoration(labelText: 'Password'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                if (_verifyHash(pass.text, note.securityHash!, note.securitySalt)) {
                                  Navigator.of(context).pop(true);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Incorrect password')),
                                  );
                                }
                              },
                              child: const Text('Unlock'),
                            ),
                          ],
                        );
                      },
                    ) ??
                    false;
              } else if (note.securityType == 'pattern') {
                unlocked = await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Enter Pattern'),
                          content: SizedBox(
                            width: 250,
                            height: 300,
                            child: PatternLock(
                              selectedColor:
                                  Theme.of(context).colorScheme.primary,
                              notSelectedColor: Colors.grey,
                              pointRadius: 10,
                              showInput: true,
                              dimension: 3,
                              onInputComplete: (List<int> input) {
                                if (_verifyHash(input.join('-'), note.securityHash!, note.securitySalt)) {
                                  Navigator.of(context).pop(true);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Incorrect pattern')),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ) ??
                    false;
              }
            }
            if (!unlocked) return;
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NoteScreen(note: note)),
            );
            if (!mounted) return;
            if (result is Map && result['pendingDelete'] != null) {
              _handlePendingDelete(result['pendingDelete'] as String);
            } else {
              setState(() => _loadNotes());
            }
          },
          onLongPress: () => _showLongPressMenu(note),
          onFavoriteToggle: () {
            setState(() {
              final updatedNote = note.copyWith(
                isFavorite: !note.isFavorite,
              );
              _storageService.saveNote(updatedNote);
              _loadNotes();
            });
          },
          mode: NoteCardMode.grid,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    String iconChar;
    String title;
    String subtitle;

    if (_showOnlySecured) {
      iconChar = '🔒';
      title = 'No secured notes';
      subtitle = 'Lock a note with a pattern or password to see it here.';
    } else if (_showOnlyFavorites) {
      iconChar = '⭐';
      title = 'No favourites yet';
      subtitle = 'Tap the star on any note to add it to favourites.';
    } else if (_selectedTag != null) {
      iconChar = '🏷️';
      title = 'No notes with this tag';
      subtitle = 'Add the tag "${_selectedTag!}" to a note to see it here.';
    } else if (_selectedFolderId != null) {
      iconChar = '📁';
      title = 'This folder is empty';
      subtitle = 'Move a note into this folder to see it here.';
    } else if (_notes.isNotEmpty) {
      iconChar = '🔍';
      title = 'No notes match';
      subtitle = 'Try a different filter.';
    } else {
      iconChar = '📝';
      title = 'No notes yet';
      subtitle = 'Tap + to write your first note!';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(iconChar, style: const TextStyle(fontSize: 44)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: onSurface,
                fontFamily: 'Nunito',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: onSurface.withAlpha(150),
                fontFamily: 'Nunito',
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderBar() {
    final folders = _storageService.getFolders();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          ...folders.map((folder) => Padding(
                padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
                child: ChoiceChip(
                  avatar: Icon(folder.icon, size: 16, color: folder.color),
                  label: Text(folder.name),
                  selected: _selectedFolderId == folder.id,
                  showCheckmark: false,
                  onSelected: (_) {
                    setState(() {
                      _selectedFolderId =
                          _selectedFolderId == folder.id ? null : folder.id;
                      _applyFilters();
                    });
                  },
                ),
              )),
          // Add-folder button — icon only
          Padding(
            padding: const EdgeInsets.only(right: 4, top: 6, bottom: 6),
            child: ActionChip(
              label: const Icon(Icons.create_new_folder_outlined, size: 18),
              onPressed: () => _showFolderDialog(null),
              tooltip: 'New Folder',
            ),
          ),
        ],
      ),
    );
  }

  void _showFolderDialog(Folder? existing) {
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'New Folder' : 'Rename Folder'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _storageService.deleteFolder(existing.id);
                if (_selectedFolderId == existing.id) {
                  setState(() {
                    _selectedFolderId = null;
                    _loadNotes();
                  });
                } else {
                  setState(() => _loadNotes());
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final folder = existing?.copyWith(name: name) ??
                  Folder(
                    name: name,
                    position: _storageService.getFolders().length,
                  );
              await _storageService.saveFolder(folder);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              setState(() => _loadNotes());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsBar() {
    // Get all unique tags
    final Set<String> tags = {};
    for (final note in _notes) {
      // Only include tags from non-secure notes unless secret filter is active
      if (_showOnlySecured) {
        if (note.isSecure) tags.addAll(note.tags);
      } else {
        if (!note.isSecure) tags.addAll(note.tags);
      }
    }

    return FadeTransition(
      opacity: _tagAnimation,
      child: Container(
        height: 50,
        margin: const EdgeInsets.only(top: 8),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // "All" tag option (always visible)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('All'),
                selected: _selectedTag == null,
                onSelected: (selected) {
                  if (selected) {
                    _selectTag(null);
                  }
                },
                avatar: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.label_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    if (_selectedTag == null)
                      Icon(
                        Icons.check,
                        color: Theme.of(context).iconTheme.color,
                        size: 14,
                      ),
                  ],
                ),
                showCheckmark: false,
                labelStyle: Theme.of(context).chipTheme.labelStyle,
                backgroundColor: Theme.of(context).chipTheme.backgroundColor,
                elevation: 2,
                pressElevation: 6,
              ),
            ),
            // All other tags
            if (tags.isNotEmpty)
              ...tags.map((tag) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(tag),
                      selected: _selectedTag == tag,
                      onSelected: (selected) {
                        _selectTag(selected ? tag : null);
                      },
                      elevation: 2,
                      pressElevation: 6,
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _sortItem(String value, String label, IconData icon) {
    final selected = _sortMode == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : null),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.normal)),
        ],
      ),
    );
  }

  // Helper for slide transition
  PageRouteBuilder<T> slideRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }
}

class _DownArrowPainter extends CustomPainter {
  final Color color;
  const _DownArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FoldedCornerButtonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha((0.08 * 255).toInt())
      ..style = PaintingStyle.fill;
    final double radius = 10;
    final path = Path()
      ..moveTo(0, size.height - radius)
      ..quadraticBezierTo(0, size.height, radius, size.height)
      ..lineTo(size.width - radius, size.height)
      ..quadraticBezierTo(
          size.width, size.height, size.width, size.height - radius)
      ..lineTo(size.width, radius)
      ..quadraticBezierTo(size.width, 0, size.width - radius, 0)
      ..lineTo(10, 0)
      ..quadraticBezierTo(0, 0, 0, radius)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
