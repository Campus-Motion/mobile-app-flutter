import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/models/activity.dart';
import 'package:mobile_app/models/waypoint.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/widgets/activity_card.dart';
import 'package:mobile_app/widgets/app_button.dart';
import 'package:mobile_app/widgets/app_card.dart';
import 'package:mobile_app/widgets/error_state.dart';
import 'package:mobile_app/widgets/loading_state.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/route_map.dart';
import 'package:mobile_app/widgets/section_header.dart';
import 'package:mobile_app/widgets/stat_item.dart';

/// Screen displaying the full details of a workout, including its GPS track on a map.
class ActivityDetailsScreen extends StatefulWidget {
  final int? activityId;
  final Activity? initialActivity;
  final TileProvider? tileProvider;
  final Future<XFile?> Function()? pickFitFile;

  const ActivityDetailsScreen({
    super.key,
    required this.activityId,
    this.initialActivity,
    this.tileProvider,
    this.pickFitFile,
  });

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  final ActivityService _activityService = ActivityService();

  Activity? _activity;
  List<Waypoint> _waypoints = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _activity = widget.initialActivity;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final id = widget.activityId ?? widget.initialActivity?.id;
    if (id == null || id <= 0) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Invalid activity ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final futures = await Future.wait([
        _activityService.getActivity(id),
        _activityService.getWaypoints(id),
      ]);

      if (!mounted) return;

      setState(() {
        _activity = futures[0] as Activity;
        _waypoints = futures[1] as List<Waypoint>;
        _isLoading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load activity details';
      });
    }
  }

  String _calculatePace(Activity activity) {
    final distanceKm = ActivityCard.getActivityDistanceKm(activity);
    if (distanceKm == null || distanceKm <= 0 || activity.duration == null) {
      return '--';
    }
    final paceMin = activity.duration! / distanceKm;
    final totalSecs = (paceMin * 60.0).round();
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return "$mins:${secs.toString().padLeft(2, '0')}";
  }

  (int, int)? _calculateElevationGainLoss() =>
      Waypoint.calculateElevationGainLoss(_waypoints);

  Future<void> _addFitFile() async {
    final picker = widget.pickFitFile ?? _activityService.pickFitFile;
    final file = await picker();
    if (file == null) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final id = widget.activityId ?? _activity?.id;
      if (id == null) throw Exception('No activity ID');

      final updated = await _activityService.attachFitFile(id, file);

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading spinner

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FIT file attached successfully.')),
      );

      setState(() {
        _activity = updated;
      });
      _loadDetails();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading spinner
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error attaching FIT file: $e')));
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete activity'),
        content: Text('Are you sure you want to delete "${_activity?.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted && _activity != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      try {
        await _activityService.deleteActivity(_activity!.id);
        if (!mounted) return;
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity deleted successfully.')),
        );
        Navigator.pop(context, true); // Pop back to activities screen
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting activity: $e')));
      }
    }
  }

  void _showEditDialog() {
    if (_activity == null) return;
    final activity = _activity!;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: activity.title);
    bool isPublic = activity.isPublic;
    String selectedType = activity.type.isNotEmpty ? activity.type : 'other';

    // The activity's sport is locked IF it was auto-detected from FIT and is NOT 'other'
    final hasFit = activity.hasFit || _waypoints.isNotEmpty;
    final isTypeLocked = hasFit && (activity.type.toLowerCase() != 'other');
    final isDurationLocked =
        hasFit && (activity.duration != null && activity.duration! > 0);
    final isDistanceLocked =
        hasFit && (activity.distanceKm != null && activity.distanceKm! > 0);

    final durationController = TextEditingController(
      text: activity.duration != null && activity.duration! > 0
          ? (activity.duration! % 1 == 0
                ? activity.duration!.toInt().toString()
                : activity.duration!.toStringAsFixed(1))
          : '',
    );
    final distanceController = TextEditingController(
      text: activity.distanceKm != null && activity.distanceKm! > 0
          ? (activity.distanceKm! % 1 == 0
                ? activity.distanceKm!.toInt().toString()
                : activity.distanceKm!.toStringAsFixed(1))
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Edit activity',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(modalContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title field
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Activity Title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sport Type Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        decoration: InputDecoration(
                          labelText: 'Sport Type',
                          helperText: isTypeLocked
                              ? 'Sport locked by FIT file'
                              : null,
                          helperStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                          suffixIcon: isTypeLocked
                              ? const Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                  color: AppColors.textMuted,
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'run',
                            child: Text('Running (run)'),
                          ),
                          DropdownMenuItem(
                            value: 'cycle',
                            child: Text('Cycling (cycle)'),
                          ),
                          DropdownMenuItem(
                            value: 'walk',
                            child: Text('Walking (walk)'),
                          ),
                          DropdownMenuItem(
                            value: 'hike',
                            child: Text('Hiking (hike)'),
                          ),
                          DropdownMenuItem(
                            value: 'swim',
                            child: Text('Swimming (swim)'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Other (other)'),
                          ),
                        ],
                        onChanged: isTypeLocked
                            ? null
                            : (val) {
                                if (val != null) {
                                  setModalState(() {
                                    selectedType = val;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 16),

                      // Duration field
                      TextFormField(
                        controller: durationController,
                        readOnly: isDurationLocked,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Duration (minutes)',
                          helperText: isDurationLocked
                              ? 'Duration locked by FIT file'
                              : null,
                          helperStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                          suffixIcon: isDurationLocked
                              ? const Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                  color: AppColors.textMuted,
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a duration';
                          }
                          final parsed = double.tryParse(
                            val.trim().replaceAll(',', '.'),
                          );
                          if (parsed == null || parsed <= 0) {
                            return 'Please enter a valid duration';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Distance field
                      TextFormField(
                        controller: distanceController,
                        readOnly: isDistanceLocked,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Distance (km)',
                          helperText: isDistanceLocked
                              ? 'Distance locked by FIT file'
                              : null,
                          helperStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                          suffixIcon: isDistanceLocked
                              ? const Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                  color: AppColors.textMuted,
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) {
                          if (val != null && val.trim().isNotEmpty) {
                            final parsed = double.tryParse(
                              val.trim().replaceAll(',', '.'),
                            );
                            if (parsed == null || parsed < 0) {
                              return 'Please enter a valid distance';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Public toggle
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Make activity public'),
                        subtitle: const Text(
                          'Visible to other campus users in their feeds',
                        ),
                        value: isPublic,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          setModalState(() {
                            isPublic = val;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(modalContext);
                              final rawDuration = durationController.text
                                  .trim();
                              final parsedDuration = rawDuration.isNotEmpty
                                  ? double.tryParse(
                                      rawDuration.replaceAll(',', '.'),
                                    )
                                  : null;
                              final rawDistance = distanceController.text
                                  .trim();
                              final parsedDistance = rawDistance.isNotEmpty
                                  ? double.tryParse(
                                      rawDistance.replaceAll(',', '.'),
                                    )
                                  : null;

                              await _saveChanges(
                                title: titleController.text.trim(),
                                type: selectedType,
                                isPublic: isPublic,
                                duration: parsedDuration,
                                distanceKm: parsedDistance,
                              );
                            }
                          },
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Delete Button inside modal
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          label: const Text(
                            'Delete this activity',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(modalContext);
                            _confirmDelete();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveChanges({
    required String title,
    required String type,
    required bool isPublic,
    double? duration,
    double? distanceKm,
  }) async {
    final id = widget.activityId ?? _activity?.id;
    if (id == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final updated = await _activityService
          .updateActivity(id, <String, dynamic>{
            'title': title,
            'type': type,
            'is_public': isPublic,
            'duration': ?duration,
            'distance_km': ?distanceKm,
          });

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity updated successfully.')),
      );

      setState(() {
        _activity = updated;
      });
      _loadDetails();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating activity: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activityId == null && widget.initialActivity == null) {
      return MasterContainer(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Back',
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 40),
          const ErrorState(message: 'No activity ID was provided.'),
          const SizedBox(height: 20),
          AppButton(text: 'Go Back', onPressed: () => Navigator.pop(context)),
        ],
      );
    }

    if (_isLoading) {
      return MasterContainer(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Back',
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 80),
          const LoadingState(height: 200),
        ],
      );
    }

    if (_hasError || _activity == null) {
      return MasterContainer(
        onRefresh: _loadDetails,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Back',
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 40),
          ErrorState(
            message:
                _errorMessage ?? 'Please check your connection and try again.',
            onRetry: _loadDetails,
          ),
        ],
      );
    }

    final activity = _activity!;
    final color = ActivityCard.getActivityColor(activity.type);
    final dateFormatted = DateFormat(
      'EEEE, MMM d, yyyy • HH:mm',
    ).format(activity.createdAt);
    final distanceStr = ActivityCard.getActivityDistanceString(activity);
    String durationValue = '--';
    String? durationUnit;
    if (activity.duration != null) {
      final totalMins = activity.duration!.round();
      final hrs = totalMins ~/ 60;
      final mins = totalMins % 60;
      durationValue = hrs > 0
          ? '${hrs}h ${mins.toString().padLeft(2, '0')}'
          : '$mins';
      durationUnit = 'min';
    }
    final paceStr = _calculatePace(activity);
    final showElevation = activity.type.toLowerCase() != 'swim';
    final elevation = showElevation ? _calculateElevationGainLoss() : null;
    final elevationStr = elevation != null
        ? '+${elevation.$1} / -${elevation.$2}'
        : '--';

    return MasterContainer(
      onRefresh: _loadDetails,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: 'Back',
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            Row(
              children: [
                if (activity.isFromEvent) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event, size: 14, color: AppColors.textMuted),
                        SizedBox(width: 4),
                        Text(
                          'Event',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        activity.isPublic ? Icons.public : Icons.lock_outline,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activity.isPublic ? 'Public' : 'Private',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: _showEditDialog,
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  onPressed: _confirmDelete,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Header Card
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  ActivityCard.getActivityIcon(activity.type),
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateFormatted,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Metrics Card
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: showElevation
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: StatItem(
                              label: 'Distance',
                              value: distanceStr.replaceAll(' km', ''),
                              unit: distanceStr.contains('km') ? 'km' : null,
                            ),
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: AppColors.divider,
                        ),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: StatItem(
                              label: 'Duration',
                              value: durationValue,
                              unit: durationUnit,
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
                              label: 'Pace',
                              value: paceStr,
                              unit: paceStr != '--' ? 'min/km' : null,
                            ),
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: AppColors.divider,
                        ),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: StatItem(
                              label: 'Elevation',
                              value: elevationStr,
                              unit: elevation != null ? 'm' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatItem(
                          label: 'Distance',
                          value: distanceStr.replaceAll(' km', ''),
                          unit: distanceStr.contains('km') ? 'km' : null,
                        ),
                      ),
                    ),
                    Container(height: 40, width: 1, color: AppColors.divider),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatItem(
                          label: 'Duration',
                          value: durationValue,
                          unit: durationUnit,
                        ),
                      ),
                    ),
                    Container(height: 40, width: 1, color: AppColors.divider),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatItem(
                          label: 'Pace',
                          value: paceStr,
                          unit: paceStr != '--' ? 'min/km' : null,
                        ),
                      ),
                    ),
                  ],
                ),
        ),

        // GPS Route Map or Encouragement Card on grey background
        if (_waypoints.isNotEmpty) ...[
          const SectionHeader(
            title: 'GPS Route',
            padding: EdgeInsets.only(top: 8, bottom: 12),
          ),
          RouteMap(
            waypoints: _waypoints,
            routeColor: color,
            activityType: activity.type,
            tileProvider: widget.tileProvider,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${_waypoints.length} GPS checkpoints recorded',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                if (_waypoints.any((w) => w.altitudeM != null))
                  Text(
                    'Alt. ${_waypoints.firstWhere((w) => w.altitudeM != null).altitudeM?.toStringAsFixed(0)} m',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ] else ...[
          const SectionHeader(
            title: 'GPS Route',
            padding: EdgeInsets.only(top: 8, bottom: 12),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 40,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No GPS route recorded',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Attach a .fit file to this activity to display your route on the map and include your workout in heatmaps!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.file_upload_outlined,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Attach a .fit file',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _addFitFile,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Notes / Description
        if (activity.body != null && activity.body!.isNotEmpty) ...[
          const SectionHeader(
            title: 'Notes',
            padding: EdgeInsets.only(top: 20, bottom: 12),
          ),
          AppCard(
            child: Text(
              activity.body!,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
