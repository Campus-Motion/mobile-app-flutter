import 'dart:convert';
import 'api_service.dart';
import '../models/activity.dart';

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  final ApiService _apiService = ApiService();

  Future<List<Activity>> getActivities({int? limit, int? cursor, String? type, bool? public}) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (cursor != null) params['cursor'] = cursor.toString();
    if (type != null) params['type'] = type;
    if (public != null) params['public'] = public.toString();

    String queryString = '';
    if (params.isNotEmpty) {
      queryString = '?' + Uri(queryParameters: params).query;
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
      throw Exception('Failed to create activity');
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
