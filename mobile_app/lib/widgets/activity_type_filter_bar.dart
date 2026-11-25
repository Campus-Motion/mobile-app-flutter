import 'package:flutter/material.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/widgets/activity_card.dart';

/// Horizontal bar of activity-type filter chips supporting single-select or
/// multi-select filtering across Sport and Heatmap screens.
class ActivityTypeFilterBar extends StatelessWidget {
  static const List<({String key, String label})> activityTypes = [
    (key: 'run', label: 'Running'),
    (key: 'cycle', label: 'Cycling'),
    (key: 'walk', label: 'Walking'),
    (key: 'hike', label: 'Hiking'),
    (key: 'swim', label: 'Swimming'),
    (key: 'other', label: 'Other'),
  ];

  static const Set<String> allTypeKeys = {
    'run',
    'cycle',
    'walk',
    'hike',
    'swim',
    'other',
  };

  /// Maps any activity type string to one of [allTypeKeys], grouping unknown
  /// or empty values under `'other'`.
  static String normalizeType(String type) {
    final normalized = type.toLowerCase().trim();
    return allTypeKeys.contains(normalized) ? normalized : 'other';
  }

  final Set<String> selectedTypes;
  final ValueChanged<String> onToggle;
  final bool showCheckmark;
  final EdgeInsetsGeometry padding;

  const ActivityTypeFilterBar({
    super.key,
    required this.selectedTypes,
    required this.onToggle,
    this.showCheckmark = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (int i = 0; i < activityTypes.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _buildChip(activityTypes[i].key, activityTypes[i].label),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(String key, String label) {
    final isSelected = selectedTypes.contains(key);
    final color = ActivityCard.getActivityColor(key);
    final icon = ActivityCard.getActivityIcon(key);

    return FilterChip(
      selected: isSelected,
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? AppColors.cardBackground : color,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? AppColors.cardBackground : AppColors.textPrimary,
        ),
      ),
      backgroundColor: AppColors.surfaceLight,
      selectedColor: color,
      checkmarkColor: AppColors.cardBackground,
      showCheckmark: showCheckmark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? color : AppColors.divider),
      ),
      onSelected: (_) => onToggle(key),
    );
  }
}
