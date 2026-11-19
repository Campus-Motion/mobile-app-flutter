import 'package:flutter/material.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/models/loop_route.dart';
import 'package:mobile_app/widgets/activity_card.dart';
import 'package:mobile_app/widgets/app_button.dart';
import 'package:mobile_app/widgets/app_card.dart';
import 'package:mobile_app/widgets/sport_type_selector.dart';
import 'package:mobile_app/widgets/stat_item.dart';

/// Pre-workout card for choosing between a free workout and a target-distance
/// loop, configuring the distance slider, and previewing a generated loop.
class LoopRouteCard extends StatelessWidget {
  final bool isLoopMode;
  final double targetDistanceKm;
  final LoopRoute? generatedLoop;
  final bool isGenerating;
  final String? errorMessage;
  final ValueChanged<bool> onModeChanged;
  final ValueChanged<double> onDistanceChanged;
  final VoidCallback onGenerateLoop;

  const LoopRouteCard({
    super.key,
    required this.isLoopMode,
    required this.targetDistanceKm,
    this.generatedLoop,
    this.isGenerating = false,
    this.errorMessage,
    required this.onModeChanged,
    required this.onDistanceChanged,
    required this.onGenerateLoop,
  });

  @override
  Widget build(BuildContext context) {
    final clampedDistance = LoopRoute.clampDistanceKm(targetDistanceKm);

    return AppCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(isLoopMode ? 16 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildModeOption(
                  key: const ValueKey<String>('mode_free_workout'),
                  label: 'Free workout',
                  icon: Icons.near_me_outlined,
                  selected: !isLoopMode,
                  onTap: isGenerating ? null : () => onModeChanged(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModeOption(
                  key: const ValueKey<String>('mode_distance_loop'),
                  label: 'Distance loop',
                  icon: Icons.loop,
                  selected: isLoopMode,
                  onTap: isGenerating ? null : () => onModeChanged(true),
                ),
              ),
            ],
          ),
          if (isLoopMode) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Target distance',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${clampedDistance.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Slider(
              key: const ValueKey<String>('loop_distance_slider'),
              value: clampedDistance,
              min: LoopRoute.minDistanceKm,
              max: LoopRoute.maxDistanceKm,
              divisions: 58,
              label: '${clampedDistance.toStringAsFixed(1)} km',
              activeColor: AppColors.primary,
              inactiveColor: AppColors.divider,
              onChanged: isGenerating ? null : onDistanceChanged,
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1 km',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                Text(
                  '30 km',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Generate loop',
              icon: Icons.loop,
              variant: AppButtonVariant.outline,
              isLoading: isGenerating,
              onPressed: onGenerateLoop,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (generatedLoop != null) ...[
              const SizedBox(height: 16),
              _buildLoopPreview(generatedLoop!),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required Key key,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final backgroundColor = selected
        ? AppColors.primaryLight
        : AppColors.surfaceLight;
    final borderColor = selected ? AppColors.primary : AppColors.divider;
    final foregroundColor = selected
        ? AppColors.primary
        : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: label,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                  width: selected ? 1.5 : 1.0,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: foregroundColor),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: foregroundColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoopPreview(LoopRoute loop) {
    final accentColor = ActivityCard.getActivityColor(loop.sportType);
    final sportLabel = SportTypeSelector.getSportLabel(loop.sportType);
    final durationText = ActivityCard.getActivityDurationString(
      loop.estimatedDuration.inSeconds / 60.0,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                ActivityCard.getActivityIcon(loop.sportType),
                size: 18,
                color: accentColor,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Loop summary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (loop.isPreview)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Preview mode',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: StatItem(
                    label: 'Loop distance',
                    value: loop.estimatedDistanceKm.toStringAsFixed(1),
                    unit: 'km',
                    valueColor: accentColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  width: 1,
                  height: 32,
                  color: AppColors.divider,
                ),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: StatItem(
                    label: 'Est. duration',
                    value: durationText,
                    valueColor: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Live loop routing from your current position is in preview mode. '
                    'Estimated distance and duration are shown for $sportLabel.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
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
