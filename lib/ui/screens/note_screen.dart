import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../models/note.dart';
import '../../services/storage_service.dart';
import '../../services/image_service.dart';
import '../../services/notification_service.dart';
import '../../services/share_service.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:pattern_lock/pattern_lock.dart';
import 'package:flutter/foundation.dart';

class NoteScreen extends StatefulWidget {
  final Note note;

  const NoteScreen({super.key, required this.note});

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
  bool _isContentLoaded = false;

  // Animation variables
  late AnimationController _saveAnimationController;
  late Animation<double> _saveAnimation;
  late AnimationController _contentAnimationController;
  late Animation<double> _contentAnimation;

  late AnimationController _tagAnimationController;
  late Animation<double> _tagAnimation;

  bool _tagAdded = false;

  late quill.QuillController _quillController;

  final TextDirection _textDirection = TextDirection.ltr;

  // Add a field for the recorder
  FlutterSoundRecorder? _audioRecorder;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    _titleController = TextEditingController(text: _note.title);
    _tags = List.from(_note.tags);
    _imagePaths = List.from(_note.imagePaths);

    // Initialize QuillController with a default document
    final doc = quill.Document();
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

    // Initialize the editor content after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeEditor();
    });
  }

  Future<void> _initializeEditor() async {
    try {
      if (_note.content.isNotEmpty) {
        final doc = quill.Document.fromJson(jsonDecode(_note.content));
        _quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } catch (e) {
      // If JSON parsing fails, create a new document with the content as plain text
      final doc = quill.Document()..insert(0, _note.content);
      _quillController = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Listen for changes
    _titleController.addListener(_onContentChanged);
    _quillController.document.changes.listen((event) {
      _onContentChanged();
    });

    if (mounted) {
      setState(() {
        _isContentLoaded = true;
      });
      _contentAnimationController.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storageService = Provider.of<StorageService>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_note.isSecure) {
        _promptForSecurity();
      }
    });
  }

  @override
  void dispose() {
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
    if (!_isSaving) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) {
      return true;
    }

    final shouldAutoSave =
        _storageService.getSetting('autoSave', defaultValue: false) == true;
    if (shouldAutoSave) {
      await _saveNote(showSnackbar: false);
      if (!mounted) return false;
      Navigator.of(context).pop(true); // Return true to indicate note was saved
      return false;
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
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('DISCARD'),
          ),
          TextButton(
            onPressed: () async {
              await _saveNote();
              if (!mounted) return null;
              Navigator.of(context).pop(true);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return false;
      Navigator.of(context).pop(true); // Return true to indicate note was saved
      return false;
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

      // Handle reminder changes
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);
      if (updatedNote.reminderDateTime != null) {
        await notificationService.scheduleNoteReminder(updatedNote,
            context: context);
      }

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
            duration: const Duration(seconds: 1),
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
    final imagePath = await ImageService.pickImageFromGallery();
    if (imagePath != null) {
      setState(() {
        _imagePaths.add(imagePath);
        _hasChanges = true;
      });
      final shouldAutoSave =
          _storageService.getSetting('autoSave', defaultValue: false) == true;
      if (shouldAutoSave) {
        _saveNote(showSnackbar: false);
      }
    }
  }

  // Take new photo
  Future<void> _takePhoto() async {
    final imagePath = await ImageService.takePhoto();
    if (imagePath != null) {
      setState(() {
        _imagePaths.add(imagePath);
        _hasChanges = true;
      });
      final shouldAutoSave =
          _storageService.getSetting('autoSave', defaultValue: false) == true;
      if (shouldAutoSave) {
        _saveNote(showSnackbar: false);
      }
    }
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
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      // Cancel reminder if exists
      if (_note.reminderDateTime != null) {
        final notificationService =
            Provider.of<NotificationService>(context, listen: false);
        await notificationService.cancelNoteReminder(_note);
      }
      // Delete images
      for (final imagePath in _note.imagePaths) {
        await ImageService.deleteImage(imagePath);
      }
      await _storageService.deleteNote(_note.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
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
            const SizedBox(width: 4),
            // Reminder icon
            IconButton(
              icon: Icon(
                _note.reminderDateTime != null
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                color: appBarIconColor,
                size: 20,
              ),
              onPressed: _pickReminder,
              tooltip: _note.reminderDateTime != null
                  ? 'Edit reminder'
                  : 'Add reminder',
            ),
            const SizedBox(width: 4),
            // Save icon with animation
            AnimatedBuilder(
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
            const SizedBox(width: 4),
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    hintStyle: TextStyle(
                      color: titleTextColor.withAlpha((0.6 * 255).toInt()),
                      fontFamily: 'Nunito',
                    ),
                    filled: false,
                  ),
                ),

                // Reminder chip
                if (_note.reminderDateTime != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InputChip(
                      avatar: Icon(Icons.notifications_active,
                          size: 18, color: appBarIconColor),
                      label: Text(
                        'Remind: '
                        '${_note.reminderDateTime!.toLocal().toString().substring(0, 16)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: titleTextColor,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      onDeleted: () async {
                        // Cancel the reminder
                        final notificationService =
                            Provider.of<NotificationService>(context,
                                listen: false);
                        await notificationService.cancelNoteReminder(_note);

                        setState(() {
                          _note = _note.copyWith(reminderDateTime: null);
                          _hasChanges = true;
                        });
                      },
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
                          child:
                              Icon(Icons.label, size: 18, color: Colors.white),
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
                            color:
                                titleTextColor.withAlpha((0.7 * 255).toInt()),
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        quill.QuillSimpleToolbar(
                          controller: _quillController,
                          config: quill.QuillSimpleToolbarConfig(
                            showSubscript: false,
                            showSuperscript: false,
                            showIndent: false,
                            showDirection: false,
                            showFontFamily: false,
                            showAlignmentButtons: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Editor area with loading state
                Expanded(
                  child: Stack(
                    children: [
                      // Editor
                      FadeTransition(
                        opacity: _contentAnimation,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: borderColor,
                            ),
                          ),
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: Directionality(
                            textDirection: _textDirection,
                            child: quill.QuillEditor(
                              controller: _quillController,
                              scrollController: _scrollController,
                              focusNode: _editorFocusNode,
                              config: quill.QuillEditorConfig(
                                placeholder: 'Write your note...',
                                padding: const EdgeInsets.all(8),
                                autoFocus: false,
                                expands: true,
                                scrollable: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Loading indicator overlay
                      if (!_isContentLoaded)
                        Container(
                          color: theme.colorScheme.background.withOpacity(0.7),
                          child: const Center(
                            child: CircularProgressIndicator(),
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

  // Show date & time picker for reminder
  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _note.reminderDateTime ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _note.reminderDateTime != null
          ? TimeOfDay.fromDateTime(_note.reminderDateTime!)
          : TimeOfDay.now(),
    );
    if (pickedTime == null) return;
    final reminderDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    // Get notification service
    final notificationService =
        Provider.of<NotificationService>(context, listen: false);
    // Cancel existing reminder if any
    if (_note.reminderDateTime != null) {
      await notificationService.cancelNoteReminder(_note);
    }
    setState(() {
      _note = _note.copyWith(reminderDateTime: reminderDateTime);
      _hasChanges = true;
    });
    // Schedule new reminder
    await notificationService.scheduleNoteReminder(_note, context: context);
  }

  // Add this new method for showing share options
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
              label: const Text('Set Pattern'),
              onPressed: () {
                Navigator.of(context).pop();
                _showPatternSetupDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPatternSetupDialog() {
    List<int> pattern = [];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Draw Pattern'),
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
              final hash =
                  sha256.convert(utf8.encode(input.join('-'))).toString();
              setState(() {
                _note = _note.copyWith(
                    isSecure: true,
                    securityType: 'pattern',
                    securityHash: hash);
                _hasChanges = true;
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pattern set for note')),
              );
            },
          ),
        ),
      ),
    );
  }

  void _promptForSecurity() {
    if (_note.securityType == 'pattern') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Draw Pattern to Unlock'),
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
                final hash =
                    sha256.convert(utf8.encode(input.join('-'))).toString();
                if (hash == _note.securityHash) {
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect pattern')),
                  );
                }
              },
            ),
          ),
        ),
      );
    }
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
}
