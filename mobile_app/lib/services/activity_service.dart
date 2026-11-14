import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'api_service.dart';
import '../models/activity.dart';
import '../models/fit_import_exception.dart';
import '../models/heatmap.dart';

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  final ApiService _apiService = ApiService();

  static const maxFitBytes = 10 * 1024 * 1024;

  Future<XFile?> pickFitFile() => openFile(
    acceptedTypeGroups: [
      XTypeGroup(
        label: 'FIT activities',
        extensions: const ['fit'],
        uniformTypeIdentifiers:
            !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
            ? const ['public.data']
            : null,
      ),
    ],
    confirmButtonText: 'Choose FIT file',
  );

  Future<Activity> importFitFile(XFile file) async {
    if (!file.name.toLowerCase().endsWith('.fit')) {
      throw const FitImportException('Please choose a .fit file.');
    }
    if (await file.length() > maxFitBytes) {
      throw const FitImportException(
        'The FIT file must be no larger than 10 MiB.',
      );
    }
    return importFit(await file.readAsBytes());
  }

  bool get canImportFit => !ApiService.mockMode;

  Future<Activity> importFit(List<int> bytes) async {
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
      filename: 'activity.fit',
      field: 'file',
    );
    if (response.statusCode == 201) {
      return Activity.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw FitImportException(switch (response.statusCode) {
      413 => 'This FIT activity exceeds the import limits.',
      400 ||
      422 => 'The file is invalid or has fewer than two supported GPS points.',
      401 => 'Please sign in again before importing.',
      _ => 'FIT import is unavailable. Please try again later.',
    });
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
}
