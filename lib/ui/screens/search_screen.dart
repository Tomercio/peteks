import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../models/note.dart';
import '../widgets/note_card.dart';
import 'note_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  late StorageService _storageService;
  List<Note> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_performSearch);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storageService = Provider.of<StorageService>(context);
  }

  @override
  void dispose() {
    _searchController.removeListener(_performSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();

    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isNotEmpty) {
        _searchResults = _storageService.searchNotes(query);
      } else {
        _searchResults = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search notes...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          autofocus: true,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isSearching && _searchResults.isEmpty
                ? const Center(
                    child: Text('No matching notes found'),
                  )
                : !_isSearching
                    ? const Center(
                        child: Text('Type to search your notes'),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final note = _searchResults[index];
                          return NoteCard(
                            note: note,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NoteScreen(note: note),
                                ),
                              );

                              if (result == true) {
                                _performSearch();
                              }
                            },
                            onFavoriteToggle: null, // Disable for simplicity
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
