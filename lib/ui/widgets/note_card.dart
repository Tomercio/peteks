import 'package:flutter/material.dart';
import '../../models/note.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../theme/app_theme.dart';
import 'dart:ui' as ui;
import 'package:flutter_quill/flutter_quill.dart' as quill;

// Add enum for card mode
enum NoteCardMode { grid, list }

class NoteCard extends StatefulWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final NoteCardMode mode;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onFavoriteToggle,
    this.mode = NoteCardMode.grid,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(widget.note.modifiedAt);
    final theme = Theme.of(context);

    // Get colors based on theme
    Color cardColor;
    Color heartColor;
    Color textColor;
    Color tagBgColor;
    Color tagTextColor;

    if (theme.colorScheme.primary == AppTheme.comfyColors['primary']) {
      // Comfy theme
      cardColor = AppTheme.comfyColors['card']!;
      heartColor = AppTheme.comfyColors['heartIcon']!;
      textColor = AppTheme.comfyColors['textDark']!;
      tagBgColor = AppTheme.comfyColors['secondary']!;
      tagTextColor = AppTheme.comfyColors['textDark']!;
    } else if (theme.brightness == Brightness.dark) {
      // Dark theme
      cardColor = AppTheme.darkColors['card']!;
      heartColor = AppTheme.darkColors['accent']!;
      textColor = AppTheme.darkColors['primaryText']!;
      tagBgColor = AppTheme.darkColors['tagBg']!;
      tagTextColor = AppTheme.darkColors['primaryText']!;
    } else {
      // Light theme
      cardColor = AppTheme.lightColors['card']!;
      heartColor = AppTheme.lightColors['accent']!;
      textColor = AppTheme.lightColors['primaryText']!;
      tagBgColor = AppTheme.lightColors['tagBg']!;
      tagTextColor = AppTheme.lightColors['primaryText']!;
    }

    // List mode: horizontal card with thumbnail
    if (widget.mode == NoteCardMode.list) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: GestureDetector(
          onTapDown: (_) => _animationController.forward(),
          onTapUp: (_) {
            _animationController.reverse();
            widget.onTap();
          },
          onTapCancel: () => _animationController.reverse(),
          child: Stack(
            children: [
              Card(
                color: cardColor,
                elevation: widget.note.isPinned ? 8 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: widget.note.isPinned
                      ? BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        )
                      : BorderSide.none,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: Title and Favorite
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (widget.note.isPinned)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: Icon(
                                    Icons.push_pin,
                                    size: 16,
                                    color: textColor,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  widget.note.title.isEmpty
                                      ? 'Untitled'
                                      : widget.note.title,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    fontFamily: 'Nunito',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.onFavoriteToggle != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: IconButton(
                                    icon: Icon(
                                      widget.note.isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: heartColor,
                                      size: 20,
                                    ),
                                    onPressed: widget.onFavoriteToggle,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Favorite',
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Ultra thin blurry divider for both modes
                          ClipRRect(
                            borderRadius: BorderRadius.circular(1),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                              child: Container(
                                height: 1,
                                width: double.infinity,
                                color: Colors.white.withAlpha(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Preview with 3 dots if overflowing
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: _buildPlainPreviewWithDots(
                                widget.note.content, textColor,
                                maxLines: 2),
                          ),
                          const SizedBox(height: 8),
                          // Date and Tags Row (List Mode)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Date
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: textColor,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                              if (widget.note.tags.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: widget.note.tags.map((tag) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: tagBgColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: tagTextColor,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Nunito',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ]
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Default: grid mode (existing layout)
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) {
          _animationController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _animationController.reverse(),
        child: SizedBox(
          height: 100, // Much smaller height for 3x3 grid
          child: Stack(
            children: [
              Card(
                color: cardColor,
                elevation: widget.note.isPinned ? 8 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: widget.note.isPinned
                      ? BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1,
                        )
                      : BorderSide.none,
                ),
                margin: const EdgeInsets.all(4),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top content: title, icons, preview
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (widget.note.isPinned)
                                Padding(
                                  padding: const EdgeInsets.only(right: 1.0),
                                  child: Icon(
                                    Icons.push_pin,
                                    size: widget.mode == NoteCardMode.grid
                                        ? 12
                                        : 16,
                                    color: textColor,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  widget.note.title.isEmpty
                                      ? 'Untitled'
                                      : widget.note.title,
                                  style: TextStyle(
                                    fontSize: widget.mode == NoteCardMode.grid
                                        ? 18
                                        : 22,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    fontFamily: 'Nunito',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.onFavoriteToggle != null)
                                Padding(
                                  padding: EdgeInsets.only(
                                      left: widget.mode == NoteCardMode.grid
                                          ? 2.0
                                          : 8.0),
                                  child: IconButton(
                                    icon: Icon(
                                      widget.note.isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: heartColor,
                                      size: widget.mode == NoteCardMode.grid
                                          ? 18
                                          : 20,
                                    ),
                                    onPressed: widget.onFavoriteToggle,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Favorite',
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Centered, short blurry divider for both modes (60% width)
                          Align(
                            alignment: Alignment.center,
                            child: FractionallySizedBox(
                              widthFactor: 0.8,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(1),
                                child: BackdropFilter(
                                  filter:
                                      ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                                  child: Container(
                                    height: 1,
                                    color: Colors.white.withAlpha(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Preview area
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2.0),
                            child: _buildPlainPreviewWithDots(
                                widget.note.content, textColor,
                                maxLines: 2),
                          ),
                          // Spacer to push tags/date to the bottom
                          const Spacer(),
                          // Tags above the date (bottom of card)
                          if (widget.note.tags.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 1.0, top: 0.0),
                              child: Wrap(
                                spacing: 1,
                                runSpacing: 1,
                                children: widget.note.tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: tagBgColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: tagTextColor,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Nunito',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          // Small space between tags and date
                          if (widget.note.tags.isNotEmpty)
                            const SizedBox(height: 1),
                          // Date at the very bottom
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 8,
                              color: textColor,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildPlainPreviewWithDots(String content, Color textColor,
      {int maxLines = 5}) {
    String plain = _getNotePreview(content);
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewStyle = TextStyle(
          fontSize: 14,
          color: textColor,
          fontFamily: 'Nunito',
        );
        final tp = TextPainter(
          text: TextSpan(
            text: plain.isEmpty ? 'No content' : plain,
            style: previewStyle,
          ),
          maxLines: maxLines,
          textDirection: ui.TextDirection.ltr,
        );
        tp.layout(maxWidth: constraints.maxWidth);
        final bool isOverflowing = tp.didExceedMaxLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plain.isEmpty ? 'No content' : plain,
              style: previewStyle,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
            if (isOverflowing)
              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Text(
                  '...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
