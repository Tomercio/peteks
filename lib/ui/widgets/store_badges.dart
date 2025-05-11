import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreBadges extends StatelessWidget {
  final double height;
  final bool showBackground;

  const StoreBadges({
    super.key,
    this.height = 40,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStoreBadge(
          context,
          'assets/icons/playstore.png',
          'https://play.google.com/store/apps/details?id=com.peteks.app',
        ),
        const SizedBox(width: 16),
        _buildStoreBadge(
          context,
          'assets/icons/playstore.png',
          'https://apps.apple.com/app/peteks/id123456789', // Replace with your actual App Store ID
        ),
      ],
    );
  }

  Widget _buildStoreBadge(BuildContext context, String imagePath, String url) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        height: height,
        decoration: showBackground
            ? BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : null,
        child: Image.asset(
          imagePath,
          height: height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
