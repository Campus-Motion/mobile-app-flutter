import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'package:file_selector/file_selector.dart' show XFile;
import 'package:mobile_app/models/fit_import_exception.dart';
import 'package:mobile_app/models/heatmap.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/widgets/app_button.dart';
import 'package:mobile_app/widgets/empty_state.dart';
import 'package:mobile_app/widgets/error_state.dart';
import 'package:mobile_app/widgets/heatmap_view.dart';
import 'package:mobile_app/widgets/loading_state.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/section_header.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key, this.loadHeatmap, this.pickFitFile});

  final Future<HeatmapData?> Function()? loadHeatmap;
  final Future<XFile?> Function()? pickFitFile;
=======
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
>>>>>>> Stashed changes

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
<<<<<<< Updated upstream
  late Future<HeatmapData?> _request;
  final _activities = ActivityService();
  bool _importing = false;

  Future<HeatmapData?> _load() =>
      (widget.loadHeatmap ?? ActivityService().getHeatmap)();
=======
  final ActivityService _activityService = ActivityService();

  // Allowed disciplines per specification (other is never included)
  static const List<Map<String, dynamic>> _disciplines = [
    {'key': 'run', 'label': 'Course à pied', 'icon': Icons.directions_run},
    {'key': 'cycle', 'label': 'Cyclisme', 'icon': Icons.pedal_bike},
    {'key': 'walk', 'label': 'Marche', 'icon': Icons.directions_walk},
    {'key': 'hike', 'label': 'Randonnée', 'icon': Icons.terrain},
  ];

  String _selectedDiscipline = 'run';
  List<List<Waypoint>> _tracks = [];
  bool _isLoading = true;
  bool _hasError = false;
>>>>>>> Stashed changes

  @override
  void initState() {
    super.initState();
<<<<<<< Updated upstream
    _request = _load();
  }

  void _reload() {
    final request = _load();
    setState(() {
      _request = request;
    });
  }

  Future<void> _importFit() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final file = await (widget.pickFitFile ?? _activities.pickFitFile)();
      if (!mounted || file == null) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: const Text('Import FIT route?'),
          content: Text(
            'Import "${file.name}" as a new private activity? '
            'Your file will be sent to Campus Motion. Only GPS coordinates and '
            'timestamps will be saved; sensor fields and the original file are discarded. '
            'Importing again creates another activity.',
          ),
          actions: [
            AppButton(
              text: 'Cancel',
              width: 100,
              variant: AppButtonVariant.outline,
              onPressed: () => Navigator.pop(context, false),
            ),
            AppButton(
              text: 'Import',
              width: 100,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      await _activities.importFitFile(file);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FIT activity saved privately.')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is FitImportException
          ? error.message
          : 'The FIT file could not be imported. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
=======
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
>>>>>>> Stashed changes
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    return MasterContainer(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          text: 'Back',
          variant: AppButtonVariant.outline,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'My heatmap'),
        const SizedBox(height: 12),
        const Text(
          'Only your routes are shown. Based on your latest 20 activities with GPS data.',
        ),
        const SizedBox(height: 16),
        AppButton(
          text: 'Choose FIT file',
          icon: Icons.upload_file,
          isLoading: _importing,
          onPressed: _activities.canImportFit && !_importing
              ? _importFit
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          _activities.canImportFit
              ? 'One .fit file, up to 10 MiB. Imported activities are private.'
              : 'Demo mode shows sample data. FIT import requires the live API.',
        ),
        const SizedBox(height: 24),
        FutureBuilder<HeatmapData?>(
          future: _request,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingState(height: 320);
            }
            if (snapshot.hasError) {
              return ErrorState(
                message: 'Your heatmap could not be loaded. Please try again.',
                onRetry: _reload,
              );
            }
            final content = snapshot.data == null
                ? const EmptyState(
                    icon: Icons.map_outlined,
                    title: 'No GPS routes yet',
                    subtitle:
                        'Activities need timestamped GPS points with movement to appear here. Manually logged activities do not contain routes.',
                  )
                : HeatmapView(heatmap: snapshot.data!);
            return Column(
              children: [
                content,
                const SizedBox(height: 24),
                AppButton(text: 'Refresh', onPressed: _reload),
              ],
            );
          },
        ),
=======
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
              'Mes Heatmaps',
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
            'Visualisez l\'ensemble de vos parcours GPS par discipline.',
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
        SectionHeader(
          title: 'Carte & Tracés',
          padding: const EdgeInsets.only(bottom: 12),
        ),

        // Heatmap Content
        if (_isLoading)
          const LoadingState(height: 360)
        else if (_hasError)
          ErrorState(
            message: 'Impossible de charger la heatmap.',
            onRetry: _loadTracks,
          )
        else if (_tracks.isEmpty)
          const SizedBox(
            height: 360,
            child: EmptyState(
              icon: Icons.map_outlined,
              title: 'No GPS data',
              subtitle: 'Aucune sortie GPS enregistrée pour cette discipline.',
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
                  '${_tracks.length} ${_tracks.length > 1 ? 'sorties GPS enregistrées' : 'sortie GPS enregistrée'}',
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
>>>>>>> Stashed changes
      ],
    );
  }
}
