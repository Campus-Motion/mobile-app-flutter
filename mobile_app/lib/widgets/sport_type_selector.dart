import 'package:flutter/material.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/widgets/activity_card.dart';

/// Horizontal scrollable selector for choosing an activity sport type.
class SportTypeSelector extends StatelessWidget {
  static const List<String> sportTypes = [
    'run',
    'walk',
    'cycle',
    'hike',
    'swim',
    'climbing',
    'other',
  ];

  final String selectedType;
  final ValueChanged<String>? onSelected;
  final bool enabled;

  const SportTypeSelector({
    super.key,
    required this.selectedType,
    required this.onSelected,
    this.enabled = true,
  });

  static String getSportLabel(String type) {
    final normalized = type.trim().toLowerCase();
    if (normalized.isEmpty) return 'Other';
    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final normalizedSelection = selectedType.trim().toLowerCase();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < sportTypes.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _buildPill(sportTypes[i], normalizedSelection),
          ],
        ],
      ),
    );
  }

  Widget _buildPill(String type, String normalizedSelection) {
    final bool isSelected = normalizedSelection == type;
    final Color sportColor = ActivityCard.getActivityColor(type);
    final IconData icon = ActivityCard.getActivityIcon(type);
    final String label = getSportLabel(type);

    final Color backgroundColor = isSelected
        ? sportColor.withValues(alpha: enabled ? 0.15 : 0.08)
        : AppColors.surfaceLight;
    final Color borderColor = isSelected
        ? (enabled ? sportColor : AppColors.divider)
        : AppColors.divider;
    final Color iconColor = enabled ? sportColor : AppColors.textMuted;
    final Color textColor = isSelected
        ? (enabled ? sportColor : AppColors.textMuted)
        : (enabled ? AppColors.textPrimary : AppColors.textMuted);

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: enabled,
      label: label,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: ValueKey<String>('sport_pill_$type'),
          borderRadius: BorderRadius.circular(14),
          onTap: enabled && onSelected != null ? () => onSelected!(type) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: iconColor),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
