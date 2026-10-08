import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/models/event.dart';
import 'package:mobile_app/widgets/app_card.dart';

/// Compact, fixed-size tile previewing an upcoming [Event] (title + start time).
/// Designed for horizontal sliders; expose [onTap] to open event details.
class EventPreviewCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  static const double size = 140;

  const EventPreviewCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, HH:mm');

    return SizedBox(
      width: size,
      child: AppCard(
        margin: const EdgeInsets.only(right: 16),
        backgroundColor: AppColors.primaryLight,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.event, color: AppColors.primary, size: 32),
            const Spacer(),
            Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                height: 1.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dateFormat.format(event.startTime),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
