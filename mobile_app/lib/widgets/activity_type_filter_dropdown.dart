import 'package:flutter/material.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/widgets/activity_card.dart';
import 'package:mobile_app/widgets/activity_type_filter_bar.dart';

/// Slim, discreet dropdown button that opens a vertical multi-select menu of
/// harmonized activity types with sober black-on-white checkmarks.
class ActivityTypeFilterDropdown extends StatelessWidget {
  final Set<String> selectedTypes;
  final ValueChanged<String> onToggle;

  const ActivityTypeFilterDropdown({
    super.key,
    required this.selectedTypes,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = ActivityTypeFilterBar.activityTypes.length;
    final selectedCount = ActivityTypeFilterBar.activityTypes
        .where((t) => selectedTypes.contains(t.key))
        .length;
    final isFiltered = selectedCount < totalCount;
    final labelColor = isFiltered
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.cardBackground),
        surfaceTintColor: const WidgetStatePropertyAll(
          AppColors.cardBackground,
        ),
        elevation: const WidgetStatePropertyAll(4),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.divider),
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 4),
        ),
      ),
      menuChildren: ActivityTypeFilterBar.activityTypes.map((type) {
        final isSelected = selectedTypes.contains(type.key);
        final sportColor = ActivityCard.getActivityColor(type.key);

        return InkWell(
          key: ValueKey<String>('activity_filter_option_${type.key}'),
          onTap: () => onToggle(type.key),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 168),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.textPrimary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    ActivityCard.getActivityIcon(type.key),
                    size: 16,
                    color: sportColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    type.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
      builder: (context, controller, child) {
        return Tooltip(
          message: 'Filter activities by type',
          child: Material(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune, size: 14, color: labelColor),
                    const SizedBox(width: 5),
                    Text(
                      isFiltered
                          ? 'Filter ($selectedCount/$totalCount)'
                          : 'Filter',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.expand_more, size: 16, color: labelColor),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
