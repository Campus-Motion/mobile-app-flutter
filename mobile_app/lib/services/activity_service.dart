import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'api_service.dart';
import '../models/activity.dart';
import '../models/fit_import_exception.dart';
import '../models/heatmap.dart';
import '../models/waypoint.dart';
import 'fit_decoder.dart';
import 'fit_folder_picker.dart';

class FitFolderImportResult {
  final List<Activity> importedActivities;
  final int skippedNonFitCount;
  final int failedFitCount;

  const FitFolderImportResult({
    required this.importedActivities,
    required this.skippedNonFitCount,
    this.failedFitCount = 0,
  });

  int get importedCount => importedActivities.length;
}

class DisciplineSummary {
  final int activityCount;
  final double totalDistanceKm;
  final double totalDurationMinutes;
  final (int, int)? elevationGainLoss;
  final List<List<Waypoint>> tracks;

  const DisciplineSummary({
    required this.activityCount,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.elevationGainLoss,
    required this.tracks,
  });

  static const DisciplineSummary empty = DisciplineSummary(
    activityCount: 0,
    totalDistanceKm: 0.0,
    totalDurationMinutes: 0.0,
    elevationGainLoss: null,
    tracks: [],
  );

  factory DisciplineSummary.fromTracks(
    List<List<Waypoint>> rawTracks, {
    required String sport,
  }) {
    final normalizedSport = sport.toLowerCase().trim();
    final validTracks = normalizedSport == 'other'
        ? const <List<Waypoint>>[]
        : rawTracks.where((t) => t.length >= 2).toList();
    double distanceKm = 0.0;
    double durationMinutes = 0.0;
    for (final track in rawTracks) {
      if (track.length >= 2) {
        distanceKm += Waypoint.trackDistanceKm(track);
        final spanMin =
            track.last.recordedAt.difference(track.first.recordedAt).inSeconds /
            60.0;
        if (spanMin > 0) {
          durationMinutes += spanMin;
        }
      }
    }
    return DisciplineSummary(
      activityCount: rawTracks.length,
      totalDistanceKm: distanceKm,
      totalDurationMinutes: durationMinutes,
      elevationGainLoss: normalizedSport == 'swim'
          ? null
          : Waypoint.calculateTotalElevationGainLoss(rawTracks),
      tracks: validTracks,
    );
  }
}

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  final ApiService _apiService = ApiService();

  static const int maxFitBytes = 10 * 1024 * 1024;

  bool get canImportFit => !ApiService.mockMode;

  static XTypeGroup fitTypeGroup() => XTypeGroup(
    label: 'FIT activities',
    extensions: const ['fit', 'FIT'],
    mimeTypes: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? const ['application/octet-stream', '*/*']
        : null,
    uniformTypeIdentifiers:
        !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
        ? const ['public.data', 'public.item']
        : null,
  );

  Future<XFile?> pickFitFile() => openFile(
    acceptedTypeGroups: [fitTypeGroup()],
    confirmButtonText: 'Choose a .fit file',
  );

  Future<List<XFile>?> pickFitFolder() => pickFolderFilesPlatform();

  static bool isFitFilename(String nameOrPath) {
    final filename = nameOrPath.split(RegExp(r'[/\\]')).last.trim();
    return filename.toLowerCase().endsWith('.fit');
  }

  Future<FitFolderImportResult> importFitFolder(
    List<XFile> files, {
    String? fallbackType,
    bool isPublic = false,
  }) async {
    final fitFiles = <XFile>[];
    int skippedNonFitCount = 0;

    for (final file in files) {
      final name = file.name.isNotEmpty ? file.name : file.path;
      if (isFitFilename(name)) {
        fitFiles.add(file);
      } else {
        skippedNonFitCount++;
      }
    }

    final imported = <Activity>[];
    int failedFitCount = 0;

    for (final file in fitFiles) {
      try {
        final bytes = await file.readAsBytes();
        final localMeta = FitDecoder.parseMetadata(bytes);
        var activity = await importFitFile(file);

        final resolvedType =
            (activity.type.isNotEmpty && activity.type != 'other')
            ? activity.type
            : (localMeta.sport != 'other'
                  ? localMeta.sport
                  : (fallbackType ?? 'other'));

        final effectiveStart = localMeta.startTime ?? activity.createdAt;
        final hour = effectiveStart.hour;
        final timeOfDay = hour < 12
            ? 'Morning'
            : (hour < 17 ? 'Afternoon' : 'Evening');
        const defaultBackendTitles = {
          'Imported FIT activity',
          'Running',
          'Cycling',
          'Walking',
          'Hiking',
          'Swimming',
        };
        final resolvedTitle =
            (activity.title.isNotEmpty &&
                !defaultBackendTitles.contains(activity.title))
            ? activity.title
            : switch (resolvedType) {
                'run' => '$timeOfDay Run',
                'cycle' => '$timeOfDay Ride',
                'walk' => '$timeOfDay Walk',
                'hike' => '$timeOfDay Hike',
                'swim' => '$timeOfDay Swim',
                _ => '$timeOfDay Workout',
              };

        final dur = (activity.duration != null && activity.duration! > 0)
            ? activity.duration
            : localMeta.durationMinutes;
        final dist = (activity.distanceKm != null && activity.distanceKm! > 0)
            ? activity.distanceKm
            : localMeta.distanceKm;

        if (resolvedTitle != activity.title ||
            resolvedType != activity.type ||
            isPublic != activity.isPublic ||
            (dur != null && dur != activity.duration) ||
            (dist != null && dist != activity.distanceKm)) {
          activity = await updateActivity(activity.id, <String, dynamic>{
            'title': resolvedTitle,
            'type': resolvedType,
            'is_public': isPublic,
            'duration': ?dur,
            'distance_km': ?dist,
          });
        }

        imported.add(activity);
      } catch (_) {
        failedFitCount++;
      }
    }

    return FitFolderImportResult(
      importedActivities: imported,
      skippedNonFitCount: skippedNonFitCount,
      failedFitCount: failedFitCount,
    );
  }

  Future<Activity> importFitFile(XFile file) async {
    final filename = file.name.isNotEmpty
        ? file.name
        : file.path.split(RegExp(r'[/\\]')).last;
    if (!filename.toLowerCase().endsWith('.fit')) {
      throw const FitImportException('Please select a .fit file.');
    }
    final length = await file.length();
    if (length > maxFitBytes) {
      throw const FitImportException('The .fit file must not exceed 10 MB.');
    }
    final bytes = await file.readAsBytes();
    return importFit(
      bytes,
      filename: filename.isNotEmpty ? filename : 'activity.fit',
    );
  }

  Future<Activity> importFit(
    List<int> bytes, {
    String filename = 'activity.fit',
  }) async {
    if (bytes.isEmpty) {
      throw const FitImportException('Choose a nonempty FIT file.');
    }
    if (bytes.length > maxFitBytes) {
      throw const FitImportException(
        'The FIT file must be no larger than 10 MiB.',
      );
    }

    final response = await _apiService.uploadFile(
      '/activities/import-fit',
      bytes: bytes,
      filename: filename,
      field: 'file',
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return Activity.fromJson(data as Map<String, dynamic>);
    } else {
      throw FitImportException(switch (response.statusCode) {
        413 => 'This FIT activity exceeds the import limits.',
        400 || 422 =>
          'The file is invalid or has fewer than two supported GPS points.',
        401 => 'Please sign in again before importing.',
        _ => 'Failed to import FIT activity: ${response.statusCode}',
      });
    }
  }

  Future<List<Map<String, dynamic>>> exportActivities() async {
    final response = await _apiService.get('/activities/export');
    if (response.statusCode != 200) {
      throw Exception('Unable to export activities');
    }
    return (json.decode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<HeatmapData?> getHeatmap() async {
    final response = await _apiService
        .get('/activities/heatmap')
        .timeout(const Duration(seconds: 40));
    if (response.statusCode == 204) return null;
    if (response.statusCode != 200) {
      throw Exception('Unable to load your heatmap');
    }
    return HeatmapData.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<Activity>> getActivities({
    int? limit,
    int? cursor,
    String? type,
    bool? public,
  }) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (cursor != null) params['cursor'] = cursor.toString();
    if (type != null) params['type'] = type;
    if (public != null) params['public'] = public.toString();

    String queryString = '';
    if (params.isNotEmpty) {
      queryString = '?${Uri(queryParameters: params).query}';
    }

    final response = await _apiService.get('/activities$queryString');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> list = data['data'] as List? ?? [];
      return list.map((json) => Activity.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to load activities');
    }
  }

  Future<Activity> getActivity(int id) async {
    final response = await _apiService.get('/activities/$id');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Activity.fromJson(data);
    } else {
      throw Exception('Failed to load activity');
    }
  }

  Future<Activity> createActivity(Activity activity) async {
    final response = await _apiService.post('/activities', activity.toJson());

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return Activity.fromJson(data);
    } else {
      throw Exception(
        'Failed to create activity: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<Activity> attachFitFile(int activityId, XFile file) async {
    final filename = file.name.isNotEmpty
        ? file.name
        : file.path.split(RegExp(r'[/\\]')).last;
    if (!filename.toLowerCase().endsWith('.fit')) {
      throw const FitImportException('Please select a .fit file.');
    }
    final length = await file.length();
    if (length > maxFitBytes) {
      throw const FitImportException('The .fit file must not exceed 10 MB.');
    }
    final bytes = await file.readAsBytes();
    final meta = FitDecoder.parseMetadata(bytes);

    final response = await _apiService.uploadFile(
      '/activities/$activityId/fit',
      bytes: bytes,
      filename: filename.isNotEmpty ? filename : 'track.fit',
      field: 'file',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return Activity.fromJson(data as Map<String, dynamic>);
    } else {
      if (meta.waypoints.isNotEmpty) {
        await addWaypoints(activityId, meta.waypoints);
      }
      final updateBody = <String, dynamic>{
        'has_fit': true,
        if (meta.durationMinutes != null && meta.durationMinutes! > 0)
          'duration': meta.durationMinutes,
        if (meta.distanceKm != null && meta.distanceKm! > 0)
          'distance_km': meta.distanceKm,
        if (meta.sport != 'other') 'type': meta.sport,
      };
      return updateActivity(activityId, updateBody);
    }
  }

  Future<void> addWaypoints(
    int activityId,
    List<Map<String, dynamic>> waypoints,
  ) async {
    final response = await _apiService.post(
      '/activities/$activityId/waypoints',
      {'waypoints': waypoints},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add waypoints');
    }
  }

  Future<Activity> updateActivity(int id, Map<String, dynamic> body) async {
    final response = await _apiService.put('/activities/$id', body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Activity.fromJson(data);
    } else {
      throw Exception('Failed to update activity');
    }
  }

  Future<void> deleteActivity(int id) async {
    final response = await _apiService.delete('/activities/$id');

    if (response.statusCode != 200) {
      throw Exception('Failed to delete activity');
    }
  }

  Future<List<Waypoint>> getWaypoints(int activityId) async {
    final response = await _apiService.get('/activities/$activityId/waypoints');

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic> list = decoded is List
          ? decoded
          : (decoded is Map && decoded['data'] is List
                ? decoded['data'] as List
                : []);
      return list
          .map((json) => Waypoint.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to load waypoints');
    }
  }

  Future<DisciplineSummary> getDisciplineSummary(String sport) async {
    final normalizedSport = sport.toLowerCase().trim();
    final activities = await getActivities(type: normalizedSport, limit: 200);
    final matchingActivities = activities
        .where((a) => a.type.toLowerCase().trim() == normalizedSport)
        .toList();
    final waypointsByActivity = await Future.wait(
      matchingActivities.map((activity) => getWaypoints(activity.id)),
    );

    double totalDistanceKm = 0.0;
    double totalDurationMinutes = 0.0;
    for (int i = 0; i < matchingActivities.length; i++) {
      final act = matchingActivities[i];
      final wp = waypointsByActivity[i];

      double? dur = act.duration;
      if ((dur == null || dur <= 0) && wp.length >= 2) {
        final spanMin =
            wp.last.recordedAt.difference(wp.first.recordedAt).inSeconds / 60.0;
        if (spanMin > 0) dur = spanMin;
      }
      if (dur != null && dur > 0) {
        totalDurationMinutes += dur;
      }

      double? dist = act.distanceKm;
      if (dist == null && wp.length >= 2) {
        dist = Waypoint.trackDistanceKm(wp);
      } else if (dist == null && dur != null && dur > 0) {
        dist = Activity.defaultSpeedKmh(act.type) * (dur / 60.0);
      }
      if (dist != null && dist > 0) {
        totalDistanceKm += dist;
      }
    }

    final elevationGainLoss = normalizedSport == 'swim'
        ? null
        : Waypoint.calculateTotalElevationGainLoss(waypointsByActivity);

    final tracks = normalizedSport == 'other'
        ? const <List<Waypoint>>[]
        : waypointsByActivity.where((track) => track.length >= 2).toList();

    return DisciplineSummary(
      activityCount: matchingActivities.length,
      totalDistanceKm: totalDistanceKm,
      totalDurationMinutes: totalDurationMinutes,
      elevationGainLoss: elevationGainLoss,
      tracks: tracks,
    );
  }

  Future<List<List<Waypoint>>> getDisciplineTracks(String sport) async {
    final normalizedSport = sport.toLowerCase().trim();
    if (normalizedSport == 'other') {
      return [];
    }

    final summary = await getDisciplineSummary(normalizedSport);
    return summary.tracks;
  }
}
