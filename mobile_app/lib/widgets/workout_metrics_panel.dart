import 'package:flutter/material.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/widgets/activity_card.dart';
import 'package:mobile_app/widgets/app_card.dart';
import 'package:mobile_app/widgets/stat_item.dart';

/// Recording lifecycle states displayed by [WorkoutMetricsPanel] and
/// controlled by `WorkoutControlBar`.
enum WorkoutStatus { idle, recording, paused }

/// Telemetry card displaying live workout status, elapsed duration, distance,
/// average pace, and optional target loop progress.
class WorkoutMetricsPanel extends StatelessWidget {
  final Duration elapsed;
  final double distanceKm;
  final double? paceMinPerKm;
  final WorkoutStatus status;
  final String? sportType;
  final double? targetDistanceKm;

  const WorkoutMetricsPanel({
    super.key,
    required this.elapsed,
    this.distanceKm = 0.0,
    this.paceMinPerKm,
    this.status = WorkoutStatus.idle,
    this.sportType,
    this.targetDistanceKm,
  });

  static String formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      final hh = hours.toString().padLeft(2, '0');
      return '$hh:$mm:$ss';
    }
    return '$mm:$ss';
  }

  static String formatDistance(double distanceKm) {
    final clamped = distanceKm < 0 ? 0.0 : distanceKm;
    return clamped.toStringAsFixed(2);
  }

  static String formatPace({
    required Duration elapsed,
    required double distanceKm,
    double? paceMinPerKm,
  }) {
    final double? effectivePace =
        paceMinPerKm ??
        ((distanceKm > 0 && elapsed.inSeconds > 0)
            ? (elapsed.inSeconds / 60.0) / distanceKm
            : null);

    if (effectivePace == null ||
        effectivePace <= 0 ||
        !effectivePace.isFinite) {
      return '--:--';
    }

    final totalSeconds = (effectivePace * 60).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static String getStatusLabel(WorkoutStatus status) {
    switch (status) {
      case WorkoutStatus.idle:
        return 'Ready';
      case WorkoutStatus.recording:
        return 'Recording';
      case WorkoutStatus.paused:
        return 'Paused';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = sportType != null
        ? ActivityCard.getActivityColor(sportType!)
        : AppColors.primary;

    final Color badgeForeground;
    final Color badgeBackground;
    final IconData badgeIcon;

    switch (status) {
      case WorkoutStatus.idle:
        badgeForeground = AppColors.textSecondary;
        badgeBackground = AppColors.surfaceLight;
        badgeIcon = Icons.flag_outlined;
        break;
      case WorkoutStatus.recording:
        badgeForeground = AppColors.success;
        badgeBackground = AppColors.success.withValues(alpha: 0.12);
        badgeIcon = Icons.fiber_manual_record;
        break;
      case WorkoutStatus.paused:
        badgeForeground = AppColors.warning;
        badgeBackground = AppColors.warning.withValues(alpha: 0.12);
        badgeIcon = Icons.pause_circle_outline;
        break;
    }

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sportType != null) ...[
                Icon(
                  ActivityCard.getActivityIcon(sportType!),
                  size: 18,
                  color: accentColor,
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeForeground),
                    const SizedBox(width: 6),
                    Text(
                      getStatusLabel(status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: badgeForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatDuration(elapsed),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Elapsed time',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: StatItem(
                    label: 'Distance',
                    value: formatDistance(distanceKm),
                    unit: 'km',
                    valueColor: accentColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  width: 1,
                  height: 36,
                  color: AppColors.divider,
                ),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: StatItem(
                    label: 'Avg pace',
                    value: formatPace(
                      elapsed: elapsed,
                      distanceKm: distanceKm,
                      paceMinPerKm: paceMinPerKm,
                    ),
                    unit: 'min/km',
                    valueColor: accentColor,
                  ),
                ),
              ),
            ],
          ),
          if (targetDistanceKm != null && targetDistanceKm! > 0) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            _buildLoopProgress(accentColor),
          ],
        ],
      ),
    );
  }

  Widget _buildLoopProgress(Color accentColor) {
    final target = targetDistanceKm!;
    final clampedDistance = distanceKm < 0 ? 0.0 : distanceKm;
    final progress = (clampedDistance / target).clamp(0.0, 1.0);
    final isComplete = clampedDistance >= target;
    final barColor = isComplete ? AppColors.success : accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              isComplete ? Icons.check_circle_outline : Icons.loop,
              size: 16,
              color: barColor,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isComplete ? 'Loop target reached' : 'Loop progress',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${formatDistance(clampedDistance)} / ${target.toStringAsFixed(1)} km',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Loop progress ${(progress * 100).round()} percent',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              key: const ValueKey<String>('loop_progress_bar'),
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceLight,
              color: barColor,
            ),
          ),
        ),
      ],
    );
  }
}
