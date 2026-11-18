import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/models/activity.dart';
import 'package:mobile_app/widgets/app_card.dart';

/// Reusable activity list card for Activity Feed, Profile history, and workouts.
class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ActivityCard({
    super.key,
    required this.activity,
    this.onTap,
    this.onLongPress,
  });

  static IconData getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'run':
        return Icons.directions_run;
      case 'walk':
        return Icons.directions_walk;
      case 'cycle':
        return Icons.pedal_bike;
      case 'hike':
        return Icons.terrain;
      case 'swim':
        return Icons.pool;
      case 'climbing':
        return Icons.filter_hdr;
      default:
        return Icons.fitness_center;
    }
  }

  static Color getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'run':
        return AppColors.activityRun;
      case 'walk':
        return AppColors.activityWalk;
      case 'cycle':
        return AppColors.activityCycle;
      case 'hike':
        return AppColors.activityHike;
      case 'swim':
        return AppColors.activitySwim;
      default:
        return AppColors.activityDefault;
    }
  }

  static double getActivitySpeedKmh(String type) {
    switch (type.toLowerCase()) {
      case 'run':
        return 10.0;
      case 'walk':
        return 5.0;
      case 'cycle':
        return 20.0;
      case 'hike':
        return 4.0;
      case 'swim':
        return 2.0;
      default:
        return 5.0;
    }
  }

  static double? getActivityDistanceKm(Activity activity) {
    if (activity.distanceKm != null) return activity.distanceKm;
    if (activity.duration == null) return null;
    return getActivitySpeedKmh(activity.type) * (activity.duration! / 60.0);
  }

  static String getActivityDistanceString(Activity activity) {
    final distance = getActivityDistanceKm(activity);
    if (distance == null) return '--';
    return '${distance.toStringAsFixed(1)} km';
  }

  static String getActivityDurationString(double? minutes) {
    if (minutes == null) return '--';
    final int hrs = (minutes / 60).floor();
    final int mins = (minutes % 60).round();
    if (hrs > 0) {
      return '${hrs}h ${mins}m';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final color = getActivityColor(activity.type);
    final formattedDate = DateFormat('MMM d, yyyy').format(activity.createdAt);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: InkWell(
        onLongPress: onLongPress,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                getActivityIcon(activity.type),
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        activity.isPublic ? Icons.public : Icons.lock_outline,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (activity.duration != null || activity.distanceKm != null) ...[
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    getActivityDistanceString(activity),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    getActivityDurationString(activity.duration),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activity.type.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
