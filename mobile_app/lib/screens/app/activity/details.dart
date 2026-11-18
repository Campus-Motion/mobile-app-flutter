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

  const ActivityDetailsScreen({
    super.key,
    required this.activityId,
    this.initialActivity,
    this.tileProvider,
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
        widget.initialActivity != null
            ? Future.value(widget.initialActivity)
            : _activityService.getActivity(id),
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
    final mins = paceMin.floor();
    final secs = ((paceMin - mins) * 60).round();
    return "$mins:${secs.toString().padLeft(2, '0')}";
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
    final durationStr = ActivityCard.getActivityDurationString(
      activity.duration,
    );
    final paceStr = _calculatePace(activity);

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
                Icon(
                  activity.isPublic ? Icons.public : Icons.lock_outline,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  activity.isPublic ? 'Public' : 'Private',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatItem(
                label: 'Distance',
                value: distanceStr.replaceAll(' km', ''),
                unit: distanceStr.contains('km') ? 'km' : null,
              ),
              Container(height: 40, width: 1, color: AppColors.divider),
              StatItem(label: 'Duration', value: durationStr),
              Container(height: 40, width: 1, color: AppColors.divider),
              StatItem(
                label: 'Pace',
                value: paceStr,
                unit: paceStr != '--' ? 'min/km' : null,
              ),
            ],
          ),
        ),

        // GPS Route Map (conditioned to presence of GPS points)
        if (_waypoints.isNotEmpty) ...[
          const SectionHeader(
            title: 'GPS Route',
            padding: EdgeInsets.only(top: 8, bottom: 12),
          ),
          RouteMap(
            waypoints: _waypoints,
            routeColor: color,
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
