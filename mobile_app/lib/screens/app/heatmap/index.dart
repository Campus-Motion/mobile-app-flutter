import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/models/waypoint.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/widgets/activity_card.dart';
import 'package:mobile_app/widgets/activity_type_filter_bar.dart';
import 'package:mobile_app/widgets/discipline_stats_card.dart';
import 'package:mobile_app/widgets/empty_state.dart';
import 'package:mobile_app/widgets/error_state.dart';
import 'package:mobile_app/widgets/loading_state.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/route_map.dart';
import 'package:mobile_app/widgets/section_header.dart';

class HeatmapScreen extends StatefulWidget {
  final Future<List<List<Waypoint>>> Function(String discipline)? loadTracks;
  final Future<DisciplineSummary> Function(String discipline)? loadSummary;
  final TileProvider? tileProvider;

  const HeatmapScreen({
    super.key,
    this.loadTracks,
    this.loadSummary,
    this.tileProvider,
  });

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  final ActivityService _activityService = ActivityService();

  String _selectedDiscipline = 'run';
  DisciplineSummary _summary = DisciplineSummary.empty;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadDisciplineData();
  }

  Future<void> _loadDisciplineData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final DisciplineSummary summary;
      if (widget.loadSummary != null) {
        summary = await widget.loadSummary!(_selectedDiscipline);
      } else if (widget.loadTracks != null) {
        final tracks = await widget.loadTracks!(_selectedDiscipline);
        summary = DisciplineSummary.fromTracks(
          tracks,
          sport: _selectedDiscipline,
        );
      } else {
        summary = await _activityService.getDisciplineSummary(
          _selectedDiscipline,
        );
      }

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _onSelectDiscipline(String disciplineKey) {
    if (_selectedDiscipline == disciplineKey) return;
    setState(() {
      _selectedDiscipline = disciplineKey;
    });
    _loadDisciplineData();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = ActivityCard.getActivityColor(_selectedDiscipline);
    final showElevation = _selectedDiscipline != 'swim';
    final isOther = _selectedDiscipline == 'other';

    return MasterContainer(
      onRefresh: _loadDisciplineData,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Navigation Header
        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                'My Heatmaps & Statistics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Subtitle
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'View your statistics and GPS routes by discipline.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 16),

        // Discipline Filter Chips
        ActivityTypeFilterBar(
          selectedTypes: {_selectedDiscipline},
          onToggle: _onSelectDiscipline,
          showCheckmark: false,
        ),
        const SizedBox(height: 20),

        if (_isLoading)
          const LoadingState(height: 360)
        else if (_hasError)
          ErrorState(
            message: 'Unable to load heatmap.',
            onRetry: _loadDisciplineData,
          )
        else ...[
          const SectionHeader(
            title: 'Statistics',
            padding: EdgeInsets.only(bottom: 12),
          ),
          DisciplineStatsCard(
            activityCount: _summary.activityCount,
            totalDistanceKm: _summary.totalDistanceKm,
            totalDurationMinutes: _summary.totalDurationMinutes,
            elevationGainLoss: _summary.elevationGainLoss,
            showElevation: showElevation,
            showCountOnly: isOther,
            accentColor: activeColor,
            analyzedCount: isOther ? null : _summary.tracks.length,
          ),
          const SizedBox(height: 8),
          const SectionHeader(
            title: 'Heatmap',
            padding: EdgeInsets.only(bottom: 12),
          ),
          if (isOther)
            const SizedBox(
              height: 240,
              child: EmptyState(
                icon: Icons.map_outlined,
                title: 'No heatmap for Other',
                subtitle:
                    'Activities classified as "Other" are excluded from heatmaps.',
              ),
            )
          else if (_summary.tracks.isEmpty)
            const SizedBox(
              height: 360,
              child: EmptyState(
                icon: Icons.map_outlined,
                title: 'No GPS data',
                subtitle: 'No GPS activities recorded for this discipline.',
              ),
            )
          else
            RouteMap(
              tracks: _summary.tracks,
              routeColor: activeColor,
              activityType: _selectedDiscipline,
              height: 380,
              tileProvider: widget.tileProvider,
            ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
