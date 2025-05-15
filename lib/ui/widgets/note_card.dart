import 'package:flutter/material.dart';
import '../../models/note.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../theme/app_theme.dart';
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
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: widget.note.isSecure
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.note.title.isEmpty
                              ? 'Untitled'
                              : widget.note.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontFamily: 'Nunito',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.lock,
                                size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Secured Note',
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor.withAlpha((0.7 * 255).toInt()),
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ],
                        ),
                        // No content/preview for secure notes
                      ],
                    )
                  : Column(
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
                                  size: 14,
                                  color: textColor,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                widget.note.title.isEmpty
                                    ? 'Untitled'
                                    : widget.note.title,
                                style: TextStyle(
                                  fontSize: 20,
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
                                    size: 18,
                                  ),
                                  onPressed: widget.onFavoriteToggle,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Favorite',
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 1.5,
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB0AFAF)
                                .withAlpha((0.12 * 255).toInt()),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Preview with 3 dots if overflowing
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: _buildPlainPreviewWithDots(
                              widget.note.content, textColor,
                              maxLines: 2),
                        ),
                        const SizedBox(height: 12),
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
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: tagBgColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize: 11,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title outside the card
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  width: constraints.maxWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      widget.note.title.isEmpty
                          ? 'Untitled'
                          : widget.note.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Nunito',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ),
                ),
              ),
            ),
            // Card content
            Expanded(
              child: Card(
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
                child: SizedBox.expand(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: widget.note.isSecure
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.lock,
                                      size: 16,
                                      color: theme.colorScheme.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Secured Note',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textColor
                                          .withAlpha((0.7 * 255).toInt()),
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top content (preview)
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 2.0, left: 2.0, right: 2.0),
                                child: _buildPlainPreviewWithDots(
                                  widget.note.content,
                                  textColor,
                                  maxLines: 2,
                                ),
                              ),
                              const Spacer(), // This will push the tags and date to the bottom
                              // Tags in grid mode
                              if (widget.note.tags.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 4.0, left: 2.0, right: 2.0),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final tags = widget.note.tags;
                                      final tagWidgets = tags.map((tag) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: tagBgColor,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            tag,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: tagTextColor,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Nunito',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList();

                                      // Helper to measure tag width
                                      double measureTagWidth(String tag) {
                                        final textPainter = TextPainter(
                                          text: TextSpan(
                                            text: tag,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Nunito',
                                            ),
                                          ),
                                          textDirection:
                                              Directionality.of(context),
                                        );
                                        textPainter.layout();
                                        return textPainter.width +
                                            12; // 12 for padding
                                      }

                                      // Measure '...' width
                                      final dotsWidth = measureTagWidth('...');

                                      // Calculate which tags fit in 2 lines
                                      List<Widget> displayTags = [];
                                      double lineWidth = 0;
                                      int line = 1;
                                      int lastTagOnSecondLine = -1;
                                      for (int i = 0; i < tags.length; i++) {
                                        final tagWidth =
                                            measureTagWidth(tags[i]);
                                        if (lineWidth + tagWidth >
                                            constraints.maxWidth) {
                                          line++;
                                          if (line > 2) break;
                                          lineWidth = 0;
                                        }
                                        // If this is the second line and adding this tag + dots would overflow, add dots and break
                                        if (line == 2 &&
                                            (lineWidth + tagWidth + dotsWidth >
                                                constraints.maxWidth)) {
                                          // If nothing fits after the break, replace the last tag with dots
                                          if (displayTags.isNotEmpty) {
                                            displayTags.removeLast();
                                          }
                                          displayTags.add(Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: tagBgColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '...',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: tagTextColor,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Nunito',
                                              ),
                                            ),
                                          ));
                                          break;
                                        }
                                        displayTags.add(tagWidgets[i]);
                                        lineWidth +=
                                            tagWidth + 4; // 4 is spacing
                                        if (line == 2) {
                                          lastTagOnSecondLine =
                                              displayTags.length - 1;
                                        }
                                      }

                                      // If we broke out of the loop because of too many tags, ensure dots are at the end of the second line
                                      if (displayTags.length < tags.length) {
                                        // Remove the last tag on the second line and add dots
                                        if (lastTagOnSecondLine >= 0 &&
                                            lastTagOnSecondLine <
                                                displayTags.length) {
                                          displayTags
                                              .removeAt(lastTagOnSecondLine);
                                          displayTags.add(Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: tagBgColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '...',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: tagTextColor,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Nunito',
                                              ),
                                            ),
                                          ));
                                        }
                                      }

                                      return Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        alignment: WrapAlignment.start,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.start,
                                        children: displayTags,
                                      );
                                    },
                                  ),
                                ),
                              // Bottom row: date and heart icon, flush with card bottom
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 4.0, left: 2.0, right: 2.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: textColor,
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                    if (widget.onFavoriteToggle != null)
                                      GestureDetector(
                                        onTap: widget.onFavoriteToggle,
                                        child: Icon(
                                          widget.note.isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: heartColor,
                                          size: 16,
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
          ],
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
          textDirection: Directionality.of(context),
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
