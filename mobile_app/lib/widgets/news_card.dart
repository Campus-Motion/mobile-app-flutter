import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/models/news_item.dart';
import 'package:mobile_app/widgets/app_card.dart';

/// Displays a single [NewsItem]: optional cover photo, publish date, title and body.
/// Falls back to a broken-image placeholder when the photo fails to load.
class NewsCard extends StatelessWidget {
  final NewsItem item;
  final VoidCallback? onTap;

  static const double imageHeight = 200;

  const NewsCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final photoUrl = item.fullPhotoUrl;

    return AppCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 24),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photoUrl != null)
            Image.network(
              photoUrl,
              height: imageHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: imageHeight,
                child: Center(
                  child: Icon(Icons.broken_image, color: AppColors.textMuted, size: 50),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(item.publishedAt),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.body,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
