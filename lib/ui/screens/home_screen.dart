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

  // Add view mode state
  ViewMode _viewMode = ViewMode.list;

  // Animation for tags
  late AnimationController _tagController;
  late Animation<double> _tagAnimation;

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

    // Load view preference from settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadViewPreference();
    });
  }

  @override
  void dispose() {
    _tagController.dispose();
    _greetingController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storageService = Provider.of<StorageService>(context);
    _loadNotes();
    // Trigger greeting animation when entering the screen
    _greetingController.forward(from: 0);
  }

  void _loadViewPreference() {
    final savedViewMode =
        _storageService.getSetting('viewMode', defaultValue: 'list');
    setState(() {
      _viewMode = savedViewMode == 'grid' ? ViewMode.grid : ViewMode.list;
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
  }

  void _applyFilters() {
    setState(() {
      // Start with all notes
      _filteredNotes = List.from(_notes);

      // Apply tag filter if selected
      if (_selectedTag != null) {
        _filteredNotes = _filteredNotes
            .where((note) => note.tags.contains(_selectedTag))
            .toList();
      }

      // Apply favorites filter if enabled
      if (_showOnlyFavorites) {
        _filteredNotes =
            _filteredNotes.where((note) => note.isFavorite).toList();
      }

      // Sort notes: Pinned first, then by position, then by modified date
      _filteredNotes.sort((a, b) {
        // First pinned vs unpinned
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;

        // Between two pinned or two unpinned notes, sort by position
        if (a.position != b.position) return a.position.compareTo(b.position);

        // If position is the same (or not defined), sort by modification date
        return b.modifiedAt.compareTo(a.modifiedAt);
      });

      // Tag animation when filtering
      _tagController.reset();
      _tagController.forward();
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
    });
  }

  void _createNewNote() async {
    // Find the next position
    int maxPosition = _notes.isEmpty
        ? 0
        : _notes.map((n) => n.position).reduce((a, b) => a > b ? a : b) + 1;

    // Create a new note and save it immediately
    final note = Note(
      title: '',
      content: '',
      position: maxPosition,
    );
    await _storageService.saveNote(note);

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: '/note'),
          builder: (context) => NoteScreen(note: note),
        ),
      );
      if (!mounted) return;
      setState(() {
        _loadNotes();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final nickname = storageService.getNickname();
    String? greeting;
    if (nickname != null && nickname.trim().isNotEmpty) {
      final hour = DateTime.now().hour;
      if (hour < 5) {
        greeting = 'Good night, $nickname! 😴';
      } else if (hour < 12) {
        greeting = 'Good morning, $nickname! 🌞';
      } else if (hour < 18) {
        greeting = 'Good afternoon, $nickname! 🌞';
      } else {
        greeting = 'Good evening, $nickname! 🌙';
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/peteks.png',
          height: 80,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        actions: [
          // View mode toggle (move before favorites)
          IconButton(
            icon: Icon(
                _viewMode == ViewMode.grid ? Icons.view_list : Icons.grid_view),
            onPressed: _toggleViewMode,
            tooltip: _viewMode == ViewMode.grid ? 'List view' : 'Grid view',
          ),
          // Favorites filter
          IconButton(
            icon: Icon(
                _showOnlyFavorites ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavoritesFilter,
            tooltip: 'Show favorites',
          ),
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(name: '/search'),
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          // Settings with proper provider approach
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final themeService =
                  Provider.of<ThemeService>(context, listen: false);
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  settings: const RouteSettings(name: '/settings'),
                  builder: (context) => ChangeNotifierProvider.value(
                    value: themeService,
                    child: const SettingsScreen(),
                  ),
                ),
              );
              if (result == true) {
                setState(() {}); // Rebuild to update greeting
              }
            },
            tooltip: 'Settings',
          ),
        ],
      ),

      // Tags bar
      body: Column(
        children: [
          if (greeting != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, left: 20, bottom: 8),
                child: FadeTransition(
                  opacity: _greetingFade,
                  child: SlideTransition(
                    position: _greetingSlide,
                    child: Text(
                      greeting,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.light
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
          if (_notes.isNotEmpty) _buildTagsBar(),

          // Notes display - Grid or List
          Expanded(
            child: _filteredNotes.isEmpty
                ? Center(
                    child: Text(
                      _selectedTag != null || _showOnlyFavorites
                          ? 'No notes match your filters'
                          : 'No notes yet. Tap + to create one!',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                : (_viewMode == ViewMode.list
                    ? _buildListView()
                    : _buildGridView()),
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
                                final hash = sha256
                                    .convert(utf8.encode(pass.text))
                                    .toString();
                                if (hash == note.securityHash) {
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
                                final hash = sha256
                                    .convert(utf8.encode(input.join('-')))
                                    .toString();
                                if (hash == note.securityHash) {
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
            await Navigator.push(
              context,
              MaterialPageRoute(
                settings: const RouteSettings(name: '/note'),
                builder: (context) => NoteScreen(note: note),
              ),
            );
            if (!mounted) return;
            setState(() {
              _loadNotes();
            });
          },
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
        crossAxisCount: 2,
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
                                final hash = sha256
                                    .convert(utf8.encode(pass.text))
                                    .toString();
                                if (hash == note.securityHash) {
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
                                final hash = sha256
                                    .convert(utf8.encode(input.join('-')))
                                    .toString();
                                if (hash == note.securityHash) {
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
            await Navigator.push(
              context,
              MaterialPageRoute(
                settings: const RouteSettings(name: '/note'),
                builder: (context) => NoteScreen(note: note),
              ),
            );
            if (!mounted) return;
            setState(() {
              _loadNotes();
            });
          },
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

  Widget _buildTagsBar() {
    // Get all unique tags
    final Set<String> tags = {};
    for (final note in _notes) {
      tags.addAll(note.tags);
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
                avatar: _selectedTag == null
                    ? const Icon(Icons.check, size: 18, color: Colors.green)
                    : Icon(Icons.label_outline,
                        color: Theme.of(context).colorScheme.primary),
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
}
