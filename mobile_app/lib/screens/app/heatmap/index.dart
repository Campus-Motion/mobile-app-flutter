import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/models/waypoint.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/widgets/activity_card.dart';
import 'package:mobile_app/widgets/empty_state.dart';
import 'package:mobile_app/widgets/error_state.dart';
import 'package:mobile_app/widgets/loading_state.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/route_map.dart';
import 'package:mobile_app/widgets/section_header.dart';

class HeatmapScreen extends StatefulWidget {
  final Future<List<List<Waypoint>>> Function(String discipline)? loadTracks;
  final TileProvider? tileProvider;

  const HeatmapScreen({super.key, this.loadTracks, this.tileProvider});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  final ActivityService _activityService = ActivityService();

  // Allowed disciplines per specification (other is never included)
  static const List<Map<String, dynamic>> _disciplines = [
    {'key': 'run', 'label': 'Running', 'icon': Icons.directions_run},
    {'key': 'cycle', 'label': 'Cycling', 'icon': Icons.pedal_bike},
    {'key': 'walk', 'label': 'Walking', 'icon': Icons.directions_walk},
    {'key': 'hike', 'label': 'Hiking', 'icon': Icons.terrain},
  ];

  String _selectedDiscipline = 'run';
  List<List<Waypoint>> _tracks = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final tracks = widget.loadTracks != null
          ? await widget.loadTracks!(_selectedDiscipline)
          : await _activityService.getDisciplineTracks(_selectedDiscipline);

      if (!mounted) return;
      setState(() {
        _tracks = tracks;
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
    _loadTracks();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = ActivityCard.getActivityColor(_selectedDiscipline);

    return MasterContainer(
      onRefresh: _loadTracks,
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
            const Text(
              'My Heatmaps',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Subtitle
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'View all your GPS routes by discipline.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 16),

        // Discipline Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _disciplines.map((d) {
              final key = d['key'] as String;
              final label = d['label'] as String;
              final icon = d['icon'] as IconData;
              final isSelected = key == _selectedDiscipline;
              final color = ActivityCard.getActivityColor(key);

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  selected: isSelected,
                  avatar: Icon(
                    icon,
                    size: 18,
                    color: isSelected ? Colors.white : color,
                  ),
                  label: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  backgroundColor: AppColors.surfaceLight,
                  selectedColor: color,
                  checkmarkColor: Colors.white,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? color : AppColors.divider,
                    ),
                  ),
                  onSelected: (_) => _onSelectDiscipline(key),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Map Section Header
        const SectionHeader(
          title: 'Map & Routes',
          padding: EdgeInsets.only(bottom: 12),
        ),

        // Heatmap Content
        if (_isLoading)
          const LoadingState(height: 360)
        else if (_hasError)
          ErrorState(message: 'Unable to load heatmap.', onRetry: _loadTracks)
        else if (_tracks.isEmpty)
          const SizedBox(
            height: 360,
            child: EmptyState(
              icon: Icons.map_outlined,
              title: 'No GPS data',
              subtitle: 'No GPS activities recorded for this discipline.',
            ),
          )
        else ...[
          RouteMap(
            tracks: _tracks,
            routeColor: activeColor,
            height: 380,
            tileProvider: widget.tileProvider,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Icon(Icons.route, size: 18, color: activeColor),
                const SizedBox(width: 8),
                Text(
                  '${_tracks.length} ${_tracks.length > 1 ? 'recorded GPS activities' : 'recorded GPS activity'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
