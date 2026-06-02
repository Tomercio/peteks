import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../models/note.dart';
import '../../services/storage_service.dart';
import '../../services/image_service.dart';
import '../../services/share_service.dart';
import '../../utils/pending_delete.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:pattern_lock/pattern_lock.dart';
import 'package:flutter/foundation.dart';

class NoteScreen extends StatefulWidget {
  final Note note;
  final bool isNew;

  const NoteScreen({super.key, required this.note, this.isNew = false});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> with TickerProviderStateMixin {
  late TextEditingController _titleController;
  late StorageService _storageService;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late Note _note;
  bool _hasChanges = false;
  List<String> _tags = [];
  List<String> _imagePaths = [];
  bool _isSaving = false;
  bool _autoSaveDone = false;
  Timer? _autoSaveTimer;

  // Animation variables
  late AnimationController _saveAnimationController;
  late Animation<double> _saveAnimation;
  late AnimationController _contentAnimationController;
  late Animation<double> _contentAnimation;

  late AnimationController _tagAnimationController;
  late Animation<double> _tagAnimation;

  bool _tagAdded = false;

  late quill.QuillController _quillController;
  bool _isRTL = false;

  // Add a field for the recorder
  FlutterSoundRecorder? _audioRecorder;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    _titleController = TextEditingController(text: _note.title);
    _tags = List.from(_note.tags);
    _imagePaths = List.from(_note.imagePaths);

    // Initialize QuillController with actual content immediately (no setState swap)
    quill.Document doc;
    try {
      if (_note.content.isNotEmpty) {
        doc = quill.Document.fromJson(jsonDecode(_note.content));
      } else {
        doc = quill.Document();
      }
    } catch (_) {
      doc = quill.Document()..insert(0, _note.content);
    }
    _quillController = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Initialize animations
    _saveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _saveAnimation = CurvedAnimation(
      parent: _saveAnimationController,
      curve: Curves.easeInOut,
    );

    _tagAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _tagAnimation = CurvedAnimation(
      parent: _tagAnimationController,
      curve: Curves.elasticOut,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _contentAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeIn,
    );

    // Start content animation immediately
    _contentAnimationController.forward();

    // Initialize the editor content after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeEditor();
    });
  }

  void _initializeEditor() {
    // Content already loaded in initState — just attach listeners here
    _titleController.addListener(_onContentChanged);
    _quillController.document.changes.listen((event) {
      _onContentChanged();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storageService = Provider.of<StorageService>(context, listen: false);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.removeListener(_onContentChanged);
    _titleController.dispose();
    _saveAnimationController.dispose();
    _tagAnimationController.dispose();
    _contentAnimationController.dispose();
    _editorFocusNode.dispose();
    _scrollController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    if (_isSaving) return;
    setState(() {
      _hasChanges = true;
      _autoSaveDone = false;
    });
    final autoSave =
        _storageService.getSetting('autoSave', defaultValue: false) == true;
    if (autoSave && _titleController.text.trim().isNotEmpty) {
      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer(const Duration(seconds: 2), () async {
        await _saveNote(showSnackbar: false);
        if (mounted) setState(() => _autoSaveDone = true);
      });
    }
  }

  Future<bool> _onWillPop() async {
    // If this is a new note with no title, just discard it silently
    if (widget.isNew && _titleController.text.trim().isEmpty) {
      return true;
    }

    if (!_hasChanges) {
      return true;
    }

    final shouldAutoSave =
        _storageService.getSetting('autoSave', defaultValue: false) == true;
    if (shouldAutoSave) {
      await _saveNote(showSnackbar: false);
      return true;
    }

    // Show confirmation dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save changes?'),
        content:
            const Text('Your changes will be lost if you don\'t save them.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Close dialog
              Navigator.of(context).pop(); // Pop the note screen
            },
            child: const Text('DISCARD'),
          ),
          TextButton(
            onPressed: () async {
              await _saveNote();
              if (!mounted) return;
              Navigator.of(context).pop(true);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return false;
      return true; // Let WillPopScope handle the pop
    }
    return result ?? false;
  }

  Future<void> _saveNote(
      {bool showPinSnackbar = false, bool showSnackbar = true}) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Activate save animation
      _saveAnimationController.forward();

      final updatedNote = _note.copyWith(
        title: _titleController.text.trim(),
        content: jsonEncode(_quillController.document.toDelta().toJson()),
        tags: _tags,
        imagePaths: _imagePaths,
        modifiedAt: DateTime.now(),
      );

      await _storageService.saveNote(updatedNote);
      _note = updatedNote;
      _hasChanges = false;

      // Show confirmation
      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              showPinSnackbar
                  ? (_note.isPinned ? 'Pinned!' : 'Unpinned!')
                  : 'Note saved',
            ),
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
    // Reset animation
    _saveAnimationController.reverse();
  }

  void _toggleFavorite() {
    setState(() {
      _note = _note.copyWith(
        isFavorite: !_note.isFavorite,
        modifiedAt: DateTime.now(),
      );
      _hasChanges = true;
    });
    _saveNote(showSnackbar: true);
  }

  void _togglePin() {
    setState(() {
      _note = _note.copyWith(
        isPinned: !_note.isPinned,
        modifiedAt: DateTime.now(),
      );
      _hasChanges = true;
    });
    _saveNote(showPinSnackbar: true, showSnackbar: true);
  }

  // Add/remove images
  void _showImageOptions() {
    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Not supported'),
          content: Text('Image picking is not available on web.'),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () async {
                Navigator.pop(context);
                await _takePhoto();
              },
            ),
            if (_imagePaths.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('View/manage images'),
                onTap: () {
                  Navigator.pop(context);
                  _showImagesManagement();
                },
              ),
          ],
        ),
      ),
    );
  }

  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final imagePath = await ImageService.pickImageFromGallery();
      if (imagePath != null) {
        setState(() {
          _imagePaths.add(imagePath);
          _hasChanges = true;
        });
        if (_isAutoSaveOn) _saveNote(showSnackbar: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: ${_friendlyError(e)}')),
        );
      }
    }
  }

  // Take new photo
  Future<void> _takePhoto() async {
    try {
      final imagePath = await ImageService.takePhoto();
      if (imagePath != null) {
        setState(() {
          _imagePaths.add(imagePath);
          _hasChanges = true;
        });
        if (_isAutoSaveOn) _saveNote(showSnackbar: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not take photo: ${_friendlyError(e)}')),
        );
      }
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('permission')) return 'Permission denied';
    if (msg.contains('network') || msg.contains('socket')) return 'Network error';
    return 'Something went wrong';
  }

  // Show and manage images
  void _showImagesManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Images'),
        content: SizedBox(
          width: double.maxFinite,
          child: _imagePaths.isEmpty
              ? const Center(child: Text('No images'))
              : GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _imagePaths.length,
                  itemBuilder: (context, index) {
                    final imagePath = _imagePaths[index];
                    final file = File(imagePath);

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          onTap: () => _showFullImage(imagePath),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: file.existsSync()
                                ? Image.file(file, fit: BoxFit.cover)
                                : Container(
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.broken_image),
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  // Show full-size image
  void _showFullImage(String imagePath) {
    final file = File(imagePath);
    if (!file.existsSync()) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _imagePaths.remove(imagePath);
                    _hasChanges = true;
                  });
                },
              ),
            ],
          ),
          body: Container(
            color: Colors.black,
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.file(file),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Remove image
  void _removeImage(int index) {
    setState(() {
      // Don't delete the actual image until note is saved
      _imagePaths.removeAt(index);
      _hasChanges = true;
    });
    final shouldAutoSave =
        _storageService.getSetting('autoSave', defaultValue: false) == true;
    if (shouldAutoSave) {
      _saveNote(showSnackbar: false);
    }
    Navigator.of(context).pop(); // Close dialog
    _showImagesManagement(); // Reopen with updated content
  }

  Future<void> _deleteNote() async {
    // Save current note state so undo can restore it
    final noteToDelete = _note;
    final imagePathsSnapshot = List<String>.from(_imagePaths);

    // Navigate back immediately, passing the note id as pending-delete
    if (!mounted) return;
    Navigator.of(context).pop({'pendingDelete': noteToDelete.id});

    // The home screen handles the actual delete + undo SnackBar
    // We store the note snapshot in a static so home_screen can access it
    PendingDelete.set(noteToDelete, imagePathsSnapshot);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appBarIconColor = theme.brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF1C1B1F);
    final titleTextColor = theme.brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF1C1B1F);
    final borderColor = theme.brightness == Brightness.dark
        ? Colors.grey[800]
        : Colors.grey[300];

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: appBarIconColor, size: 20),
          title: null,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) Navigator.of(context).pop();
            },
          ),
          actions: [
            // Favorite icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: IconButton(
                key: ValueKey<bool>(_note.isFavorite),
                icon: Icon(
                  _note.isFavorite ? Icons.star : Icons.star_border,
                  color: appBarIconColor,
                  size: 20,
                ),
                onPressed: _toggleFavorite,
                tooltip: 'Toggle favorite',
              ),
            ),
            const SizedBox(width: 4),
            // Pin icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: IconButton(
                key: ValueKey<bool>(_note.isPinned),
                icon: Icon(
                  _note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: appBarIconColor,
                  size: 20,
                ),
                onPressed: _togglePin,
                tooltip: 'Toggle pin',
              ),
            ),
            // Save button or auto-save indicator (no gap when idle)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _isAutoSaveOn
                  ? (_isSaving
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: appBarIconColor.withAlpha(128),
                            ),
                          ),
                        )
                      : _autoSaveDone
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(
                                Icons.check,
                                size: 16,
                                color: appBarIconColor.withAlpha(160),
                              ),
                            )
                          : const SizedBox.shrink())
                  : AnimatedBuilder(
                      animation: _saveAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_saveAnimation.value * 0.2),
                          child: IconButton(
                            icon: Icon(
                              _isSaving ? Icons.hourglass_empty : Icons.save,
                              color: appBarIconColor,
                              size: 20,
                            ),
                            onPressed: _isSaving ? null : _saveNote,
                            tooltip: _isSaving ? 'Saving...' : 'Save',
                          ),
                        );
                      },
                    ),
            ),
            // Popup menu
            PopupMenuButton<String>(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF222428)
                  : Colors.white,
              icon: Icon(Icons.more_vert, color: appBarIconColor, size: 20),
              onSelected: (value) {
                if (value == 'share') {
                  _showShareOptions();
                } else if (value == 'delete') {
                  _deleteNote();
                } else if (value == 'image') {
                  _showImageOptions();
                } else if (value == 'audio') {
                  _addVoiceRecording();
                } else if (value == 'secure_toggle') {
                  setState(() {
                    if (_note.isSecure) {
                      _note = _note.copyWith(
                        isSecure: false,
                        securityType: null,
                        securityHash: null,
                      );
                      _hasChanges = true;
                      _saveNote(showSnackbar: true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Security removed from note')),
                      );
                    } else {
                      _showSecureNoteDialog();
                    }
                  });
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share,
                          size: 18,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87),
                      const SizedBox(width: 8),
                      Text('Share',
                          style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black87)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 18,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87),
                      const SizedBox(width: 8),
                      Text('Delete',
                          style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black87)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'image',
                  child: Row(
                    children: [
                      Icon(Icons.image_outlined,
                          size: 18,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87),
                      const SizedBox(width: 8),
                      Text('Upload Image',
                          style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black87)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'audio',
                  child: Row(
                    children: [
                      Icon(Icons.mic,
                          size: 18,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87),
                      const SizedBox(width: 8),
                      Text('Add Voice Recording',
                          style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black87)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'secure_toggle',
                  child: Row(
                    children: [
                      Icon(_note.isSecure ? Icons.lock_open : Icons.lock,
                          size: 18,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87),
                      const SizedBox(width: 8),
                      Text(_note.isSecure ? 'Remove Security' : 'Make Secure',
                          style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Hero(
          tag: 'note-${_note.id}',
          child: Material(
            color: theme.colorScheme.surface,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Secure note banner
                    if (_note.isSecure)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.primary.withAlpha(80),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock,
                                size: 16,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This note is secured. On the home screen, tap the hidden box in the bottom-left corner to switch between secured and regular notes.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Nunito',
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Image display if available
                    if (_imagePaths.isNotEmpty) _buildImagePreview(),

                    // Audio player if available
                    if (_note.audioPath != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildAudioPlayer(_note.audioPath!),
                      ),

                    // Title
                    TextField(
                      controller: _titleController,
                      maxLines: null,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: titleTextColor,
                        fontFamily: 'Nunito',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: borderColor!,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 2.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        hintStyle: TextStyle(
                          color: titleTextColor.withAlpha((0.6 * 255).toInt()),
                          fontFamily: 'Nunito',
                        ),
                        filled: false,
                      ),
                    ),

                    // Date
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Edited ${_note.modifiedAt.toString().substring(0, 16)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: titleTextColor,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),

                    // Tags
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Add Tag Button (icon only, peach color, rounded)
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => _buildAddTagDialog(),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black,
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Icon(Icons.label,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                          // All tags
                          ..._tags.map((tag) {
                            final isNewTag = _tagAdded && tag == _tags.last;
                            final chip = Chip(
                              label: Text(
                                tag,
                                style: TextStyle(
                                  color: titleTextColor,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                              backgroundColor: theme.colorScheme.secondary,
                              deleteIcon: Icon(
                                Icons.close,
                                size: 18,
                                color: titleTextColor
                                    .withAlpha((0.7 * 255).toInt()),
                              ),
                              onDeleted: () {
                                setState(() {
                                  _tags.remove(tag);
                                  _hasChanges = true;
                                });
                              },
                            );
                            if (isNewTag) {
                              return ScaleTransition(
                                scale: _tagAnimation,
                                child: chip,
                              );
                            }
                            return chip;
                          }),
                        ],
                      ),
                    ),

                    // Word / character count
                    _buildWordCount(),

                    // Quill toolbar and RTL toggle in a row
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            quill.QuillSimpleToolbar(
                              controller: _quillController,
                              config: quill.QuillSimpleToolbarConfig(
                                showSubscript: false,
                                showSuperscript: false,
                                showIndent: true,
                                showDirection: false,
                                showFontFamily: false,
                                showAlignmentButtons: true,
                                showListBullets: true,
                                showListNumbers: true,
                                showUndo: true,
                                showRedo: true,
                              ),
                            ),
                            // RTL / LTR toggle
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Tooltip(
                                message: _isRTL ? 'Switch to LTR' : 'Switch to RTL',
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => setState(() => _isRTL = !_isRTL),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Text(
                                      _isRTL ? 'LTR' : 'RTL',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _isRTL
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Editor area with loading state
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: borderColor,
                        ),
                      ),
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: Stack(
                        children: [
                          // Editor with RTL/LTR support
                          FadeTransition(
                            opacity: _contentAnimation,
                            child: Directionality(
                              textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
                              child: quill.QuillEditor(
                                controller: _quillController,
                                scrollController: _scrollController,
                                focusNode: _editorFocusNode,
                                config: quill.QuillEditorConfig(
                                  placeholder: 'Write your note...',
                                  padding: const EdgeInsets.all(16),
                                  autoFocus: false,
                                  expands: false,
                                  scrollable: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddTagDialog() {
    final TextEditingController tagController = TextEditingController();

    return AlertDialog(
      title: const Text('Add Tag'),
      content: TextField(
        controller: tagController,
        decoration: const InputDecoration(
          hintText: 'Enter tag name',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        onSubmitted: (_) {
          _addTag(tagController.text);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => _addTag(tagController.text),
          child: const Text('ADD'),
        ),
      ],
    );
  }

  void _addTag(String tagText) {
    final newTag = tagText.trim();
    if (newTag.isNotEmpty && !_tags.contains(newTag)) {
      setState(() {
        _tags.add(newTag);
        _hasChanges = true;
        _tagAdded = true; // Mark that a new tag was added

        // Reset and activate the tag animation
        _tagAnimationController.reset();
        _tagAnimationController.forward();
      });
      final shouldAutoSave =
          _storageService.getSetting('autoSave', defaultValue: false) == true;
      if (shouldAutoSave) {
        _saveNote(showSnackbar: false);
      }
      Navigator.of(context).pop();
    }
  }

  // Add the _addVoiceRecording method
  Future<void> _addVoiceRecording() async {
    if (_audioRecorder == null) {
      _audioRecorder = FlutterSoundRecorder();
      await _audioRecorder!.openRecorder();
    }

    // Request microphone permission
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }

    // Get a file path
    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        '${dir.path}/note_audio_${DateTime.now().millisecondsSinceEpoch}.aac';

    // Start recording
    await _audioRecorder!.startRecorder(
      toFile: filePath,
      codec: Codec.aacADTS,
    );

    // Show a dialog to stop recording
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Recording...'),
        content: const Text('Tap stop to finish recording.'),
        actions: [
          TextButton(
            onPressed: () async {
              await _audioRecorder!.stopRecorder();
              setState(() {
                _note = _note.copyWith(audioPath: filePath);
                _hasChanges = true;
              });
              await _storageService.saveNote(_note);
              Navigator.of(context).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voice recording added')),
                );
              }
            },
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }

  // Add the _buildAudioPlayer widget
  Widget _buildAudioPlayer(String audioPath) {
    FlutterSoundPlayer audioPlayer = FlutterSoundPlayer();
    bool isPlaying = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Row(
          children: [
            IconButton(
              icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
              onPressed: () async {
                if (isPlaying) {
                  await audioPlayer.stopPlayer();
                  setState(() => isPlaying = false);
                } else {
                  await audioPlayer.openPlayer();
                  await audioPlayer.startPlayer(
                    fromURI: audioPath,
                    whenFinished: () {
                      setState(() => isPlaying = false);
                    },
                  );
                  setState(() => isPlaying = true);
                }
              },
            ),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Voice recording',
                    style: TextStyle(fontFamily: 'Nunito'))),
          ],
        );
      },
    );
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashWithSalt(String input, String salt) {
    final key = utf8.encode(salt);
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(input)).toString();
  }

  void _showSecureNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Secure Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.pattern),
              label: const Text('Create Pattern'),
              onPressed: () {
                Navigator.of(context).pop();
                _showPatternSetupDialog();
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.lock_outline),
              label: const Text('Create Password'),
              onPressed: () {
                Navigator.of(context).pop();
                _showPasswordSetupDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordSetupDialog() {
    final TextEditingController passController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final pass = passController.text;
              if (pass.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 4 characters')),
                );
                return;
              }
              if (pass != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              final salt = _generateSalt();
              final hash = _hashWithSalt(pass, salt);
              setState(() {
                _note = _note.copyWith(
                  isSecure: true,
                  securityType: 'password',
                  securityHash: hash,
                  securitySalt: salt,
                );
                _hasChanges = true;
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '🔒 Note secured! Go back — tap the lock icon on the note card to unlock it next time.',
                  ),
                  duration: Duration(seconds: 4),
                ),
              );
            },
            child: const Text('SET'),
          ),
        ],
      ),
    );
  }

  void _showPatternSetupDialog() {
    List<int> pattern = [];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Pattern'),
        content: SizedBox(
          width: 250,
          height: 300,
          child: PatternLock(
            selectedColor: Theme.of(context).colorScheme.primary,
            notSelectedColor: Colors.grey,
            pointRadius: 10,
            showInput: true,
            dimension: 3,
            onInputComplete: (List<int> input) {
              if (input.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pattern too short')),
                );
                return;
              }
              pattern = input;
              Navigator.of(context).pop();
              _confirmPattern(pattern);
            },
          ),
        ),
      ),
    );
  }

  void _confirmPattern(List<int> pattern) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Pattern'),
        content: SizedBox(
          width: 250,
          height: 300,
          child: PatternLock(
            selectedColor: Theme.of(context).colorScheme.primary,
            notSelectedColor: Colors.grey,
            pointRadius: 10,
            showInput: true,
            dimension: 3,
            onInputComplete: (List<int> input) {
              if (input.length < 4 || !listEquals(input, pattern)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Patterns do not match')),
                );
                return;
              }
              final salt = _generateSalt();
              final hash = _hashWithSalt(input.join('-'), salt);
              setState(() {
                _note = _note.copyWith(
                  isSecure: true,
                  securityType: 'pattern',
                  securityHash: hash,
                  securitySalt: salt,
                );
                _hasChanges = true;
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '🔒 Note secured! Go back — tap the lock icon on the note card to unlock it next time.',
                  ),
                  duration: Duration(seconds: 4),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Build the image preview widget
  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _imagePaths.length + 1, // +1 for add button
        itemBuilder: (context, index) {
          // If this is the last item - add button
          if (index == _imagePaths.length) {
            return GestureDetector(
              onTap: _showImageOptions,
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha((0.2 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withAlpha((0.3 * 255).toInt()),
                  ),
                ),
                child: const Icon(
                  Icons.add_photo_alternate,
                  color: Colors.grey,
                  size: 40,
                ),
              ),
            );
          }

          // Otherwise, it's an existing image
          final imagePath = _imagePaths[index];
          final file = File(imagePath);

          return GestureDetector(
            onTap: () => _showFullImage(imagePath),
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: file.existsSync()
                        ? Image.file(
                            file,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.broken_image,
                                color: Colors.grey),
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _imagePaths.removeAt(index);
                        _hasChanges = true;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWordCount() {
    final plainText = _quillController.document.toPlainText();
    final chars = plainText.replaceAll('\n', '').length;
    final words = plainText
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Opacity(
        opacity: 0.45,
        child: Text(
          '$words words · $chars characters',
          style: const TextStyle(fontSize: 11, fontFamily: 'Nunito'),
        ),
      ),
    );
  }

  bool get _isAutoSaveOn =>
      _storageService.getSetting('autoSave', defaultValue: false) == true;

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_snippet),
              title: const Text('Share as Text'),
              subtitle: const Text('Share note content as plain text'),
              onTap: () {
                Navigator.pop(context);
                ShareService().shareAsText(_note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Share as Markdown'),
              subtitle: const Text('Share note with markdown formatting'),
              onTap: () {
                Navigator.pop(context);
                ShareService().shareAsMarkdown(_note);
              },
            ),
            if (_imagePaths.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.file_copy),
                title: const Text('Share as File'),
                subtitle: const Text('Share note and images as files'),
                onTap: () {
                  Navigator.pop(context);
                  ShareService().shareAsFile(_note);
                },
              ),
          ],
        ),
      ),
    );
  }
}

