import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/note.dart';
import 'package:intl/intl.dart';

class NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onPinToggle;

  const NoteListItem({
    super.key,
    required this.note,
    required this.onTap,
    this.onFavoriteToggle,
    this.onPinToggle,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(note.modifiedAt);

    final theme = Theme.of(context);
    Color cardColor;
    if (theme.brightness == Brightness.dark) {
      cardColor = const Color(0xFF222222); // dark mode
    } else if (theme.colorScheme.primary == const Color(0xFFC2B280)) {
      cardColor = const Color(0xFFF5E9DA); // desert mode
    } else {
      cardColor = Colors.white; // light mode
    }
    final useBlackText = theme.brightness != Brightness.dark;

    final Color textColor = useBlackText ? Colors.black : Colors.white;
    final Color titleColor = useBlackText ? Colors.black : Colors.white;
    final Color dateColor = useBlackText ? Colors.black : Colors.white;

    return Card(
      color: cardColor,
      elevation: note.isPinned ? 6 : 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: note.isPinned
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // תמונה ממוזערת (אם יש)
              if (note.thumbnailImage != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 70,
                      height: 70,
                      child: _buildThumbnail(note.thumbnailImage!),
                    ),
                  ),
                ),

              // צד שמאל עם התוכן המרכזי
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // שורה עליונה עם כותרת וסמנים
                    Row(
                      children: [
                        if (note.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.push_pin,
                              size: 16,
                              color: textColor,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            note.title.isEmpty ? 'Untitled' : note.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // תצוגה מקדימה של התוכן
                    Text(
                      note.preview.isEmpty ? 'No content' : note.preview,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // צג מספר תמונות אם יש יותר מאחת
                    if (note.imagePaths.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.photo_library,
                              size: 14,
                              color: textColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${note.imagePaths.length} images',
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // שורה תחתונה עם תאריך ותגיות
                    Row(
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: dateColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (note.tags.isNotEmpty)
                          Expanded(
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: note.tags.map((tag) {
                                final isDarkMode =
                                    Theme.of(context).brightness ==
                                        Brightness.dark;
                                final tagBgColor = isDarkMode
                                    ? Colors.white24
                                    : Colors.grey.shade200;
                                final tagTextColor =
                                    isDarkMode ? Colors.white : Colors.black;
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
                  ],
                ),
              ),

              // צד ימין עם פעולות מהירות
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onFavoriteToggle != null)
                    IconButton(
                      icon: Icon(
                        note.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 20,
                        color: note.isFavorite ? Colors.redAccent : textColor,
                      ),
                      onPressed: onFavoriteToggle,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                      splashRadius: 20,
                      tooltip: 'Toggle favorite',
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String imagePath) {
    // בדיקה אם התמונה קיימת
    final file = File(imagePath);

    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else {
      return Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
  }
}
