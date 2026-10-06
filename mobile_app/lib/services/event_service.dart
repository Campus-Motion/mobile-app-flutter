import 'dart:convert';
import 'api_service.dart';
import '../models/event.dart';
import '../models/user.dart';

class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  final ApiService _apiService = ApiService();

  Future<List<Event>> getEvents({int? limit, String? offset, String? after}) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (offset != null) params['offset'] = offset;
    if (after != null) params['after'] = after;

    String queryString = '';
    if (params.isNotEmpty) {
      queryString = '?${Uri(queryParameters: params).query}';
    }

    final response = await _apiService.get('/events$queryString');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> list = data['data'] as List? ?? [];
      return list.map((json) => Event.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to load events');
    }
  }

  Future<Event> getEvent(int id) async {
    final response = await _apiService.get('/events/$id');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Event.fromJson(data);
    } else {
      throw Exception('Failed to load event');
    }
  }

  Future<void> joinEvent(int id) async {
    final response = await _apiService.post('/events/$id/participants', null);

    if (response.statusCode != 201) {
      final data = json.decode(response.body);
      final message = data['message'] as String?;
      throw Exception(message ?? 'Failed to join event');
    }
  }

  Future<void> leaveEvent(int id) async {
    final response = await _apiService.delete('/events/$id/participants');

    if (response.statusCode != 200) {
      throw Exception('Failed to leave event');
    }
  }

  Future<List<User>> getParticipants(int id) async {
    final response = await _apiService.get('/events/$id/participants');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> list = data['data'] as List? ?? [];
      return list.map((json) => User.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to load event participants');
    }
  }
}
