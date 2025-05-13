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
          child: Card(
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
            child: Padding(
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
                            fontSize: 16,
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
                  // Preview with 3 dots if overflowing
                  _buildPlainPreviewWithDots(widget.note.content, textColor,
                      maxLines: 2),
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
          height: 220, // Reduced height for all cards in grid mode
          child: Card(
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
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top content: title, icons, preview
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.note.isPinned)
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Icon(
                            Icons.push_pin,
                            size: 18,
                            color: textColor,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          widget.note.title.isEmpty
                              ? 'Untitled'
                              : widget.note.title,
                          style: TextStyle(
                            fontSize: 18,
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
                              size: 22,
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
                  // Preview area
                  _buildPlainPreviewWithDots(widget.note.content, textColor),
                  // Spacer to push tags/date to the bottom
                  const Spacer(),
                  // Tags above the date (bottom of card)
                  if (widget.note.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0, top: 0.0),
                      child: Wrap(
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
                    ),
                  // Small space between tags and date
                  if (widget.note.tags.isNotEmpty) const SizedBox(height: 6),
                  // Date at the very bottom
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
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
