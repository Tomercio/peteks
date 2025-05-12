import 'package:flutter/material.dart';

class ColorPickerSheet extends StatelessWidget {
  final Color initialColor;
  final Function(Color) onColorSelected;

  const ColorPickerSheet({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Add more colors including true black
    final List<Color> colors = [
      Colors.white,
      Colors.black,
      Color(0xFF424242), // Dark gray
      Color(0xFF425058), // Blue-gray
      Color(0xFF98FF98), // Mint
      Color(0xFF3EB489), // Dark Mint
      Color(0xFFFCE4EC), // Pink
      Color(0xFFE57373), // Red
      Color(0xFFFFF8E1), // Yellow
      Color(0xFFE1F5FE), // Soft blue
      Color(0xFFB39DDB), // Brand purple (optional)
      Color(0xFF232228), // Brand dark (optional)
    ];

    // שימוש ב-MediaQuery לתמיכה במסכים בגדלים שונים
    final double screenWidth = MediaQuery.of(context).size.width;
    final int itemsPerRow = (screenWidth / 70).floor(); // מחושב לפי גודל המסך
    final double itemSize =
        (screenWidth - 32 - (itemsPerRow - 1) * 12) / itemsPerRow;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Color',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              // כפתור סגירה
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: itemsPerRow,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final Color color = colors[index];
              final bool isSelected = color == initialColor;
              final bool isDark = color.computeLuminance() < 0.5;

              return GestureDetector(
                onTap: () => onColorSelected(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: itemSize,
                  height: itemSize,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(itemSize / 2),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      width: isSelected ? 3 : 1,
                    ),
                    // הוספת צל עדין לצבעים בהירים ולבן
                    boxShadow: color.computeLuminance() > 0.9
                        ? [
                            BoxShadow(
                              color: Colors.black,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: isDark ? Colors.white : Colors.black,
                          size: itemSize * 0.5,
                        )
                      : null,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
