import 'package:flutter/material.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/widgets/activity_card.dart';
import 'package:mobile_app/widgets/app_card.dart';
import 'package:mobile_app/widgets/stat_item.dart';

/// Displays aggregated statistics for a sport discipline (activity count,
/// total distance, total time, and optional total elevation gain/loss).
class DisciplineStatsCard extends StatelessWidget {
  final int activityCount;
  final double totalDistanceKm;
  final double totalDurationMinutes;
  final (int, int)? elevationGainLoss;
  final bool showElevation;
  final bool showCountOnly;
  final Color accentColor;
  final int? analyzedCount;

  const DisciplineStatsCard({
    super.key,
    required this.activityCount,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    this.elevationGainLoss,
    this.showElevation = true,
    this.showCountOnly = false,
    this.accentColor = AppColors.primary,
    this.analyzedCount,
  });

  @override
  Widget build(BuildContext context) {
    if (showCountOnly) {
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: StatItem(
              label: 'Activities',
              value: '$activityCount',
              valueColor: accentColor,
            ),
          ),
        ),
      );
    }

    final distanceValue = totalDistanceKm.toStringAsFixed(1);
    final durationValue = ActivityCard.getActivityDurationString(
      totalDurationMinutes,
    );
    final elevationValue = elevationGainLoss != null
        ? '+${elevationGainLoss!.$1} / -${elevationGainLoss!.$2}'
        : '--';
    final hasMissingFit =
        analyzedCount != null && activityCount > analyzedCount!;

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showElevation) ...[
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: StatItem(
                      label: 'Activities',
                      value: '$activityCount',
                      valueColor: accentColor,
                    ),
                  ),
                ),
                Container(height: 40, width: 1, color: AppColors.divider),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: StatItem(
                      label: 'Total distance',
                      value: distanceValue,
                      unit: 'km',
                      valueColor: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(height: 1, color: AppColors.divider),
            ),
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: StatItem(
                      label: 'Total time',
                      value: durationValue,
                      valueColor: accentColor,
                    ),
                  ),
                ),
                Container(height: 40, width: 1, color: AppColors.divider),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: StatItem(
                      label: 'Total elevation',
                      value: elevationValue,
                      unit: elevationGainLoss != null ? 'm' : null,
                      valueColor: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: StatItem(
                      label: 'Activities',
                      value: '$activityCount',
                      valueColor: accentColor,
                    ),
                  ),
                ),
                Container(height: 40, width: 1, color: AppColors.divider),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: StatItem(
                      label: 'Total distance',
                      value: distanceValue,
                      unit: 'km',
                      valueColor: accentColor,
                    ),
                  ),
                ),
                Container(height: 40, width: 1, color: AppColors.divider),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: StatItem(
                      label: 'Total time',
                      value: durationValue,
                      valueColor: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          if (hasMissingFit) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 12),
              child: Container(height: 1, color: AppColors.divider),
            ),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$analyzedCount of $activityCount ${activityCount == 1 ? 'activity includes' : 'activities include'} GPS (.fit) data.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
