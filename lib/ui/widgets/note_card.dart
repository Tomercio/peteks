import 'package:flutter/material.dart';
import '../../models/note.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../theme/app_theme.dart';
import 'dart:ui' as ui;

class NoteCard extends StatefulWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onFavoriteToggle,
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
          height: 210, // Fixed height for all cards
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
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top content: title, icons, preview
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            IconButton(
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
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Preview area
                      Flexible(
                        child: _buildPlainPreviewWithDots(
                            widget.note.content, textColor),
                      ),
                      // Tags at the bottom above the date
                      if (widget.note.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0, top: 4.0),
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
                    ],
                  ),
                ),
                // Date absolutely at the bottom left
                Positioned(
                  left: 16,
                  bottom: 8,
                  child: Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlainPreviewWithDots(String content, Color textColor) {
    String plain = '';
    if (content.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(content);
        if (decoded is List) {
          plain = decoded
              .map((op) => op['insert'])
              .whereType<String>()
              .join()
              .trim();
        } else {
          plain = content.trim();
        }
      } catch (e) {
        plain = content.trim();
      }
    }
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
          maxLines: 5,
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
              maxLines: 5,
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
