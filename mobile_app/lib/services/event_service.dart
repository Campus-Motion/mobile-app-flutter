import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'api_service.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../models/waypoint.dart';

class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  final ApiService _apiService = ApiService();

  static const int maxFitBytes = 10 * 1024 * 1024;

  Future<XFile?> pickFitFile() => openFile(
    acceptedTypeGroups: [
      XTypeGroup(
        label: 'FIT activities',
        extensions: const ['fit', 'FIT'],
        uniformTypeIdentifiers:
            !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
            ? const ['public.data']
            : null,
      ),
    ],
    confirmButtonText: 'Choisir un fichier .fit',
  );

  Future<List<Waypoint>> importEventFitFile(int eventId, XFile file) async {
    final filename = file.name.isNotEmpty
        ? file.name
        : file.path.split(RegExp(r'[/\\]')).last;
    if (!filename.toLowerCase().endsWith('.fit')) {
      throw Exception('Veuillez sélectionner un fichier .fit.');
    }
    final length = await file.length();
    if (length > maxFitBytes) {
      throw Exception('Le fichier .fit ne doit pas dépasser 10 Mo.');
    }
    final bytes = await file.readAsBytes();
    return addEventTrack(
      eventId,
      bytes,
      filename: filename.isNotEmpty ? filename : 'event.fit',
    );
  }

  Future<List<Event>> getEvents({
    int? limit,
    String? offset,
    String? after,
  }) async {
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

  Future<List<Waypoint>> getEventWaypoints(int eventId) async {
    final response = await _apiService.get('/events/$eventId/waypoints');

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
      throw Exception('Failed to load event waypoints');
    }
  }

  Future<List<Waypoint>> addEventTrack(
    int eventId,
    List<int> bytes, {
    String filename = 'event.fit',
  }) async {
    if (bytes.isEmpty) {
      throw Exception('FIT file cannot be empty');
    }

    final response = await _apiService.uploadFile(
      '/events/$eventId/import-fit',
      bytes: bytes,
      filename: filename,
      field: 'file',
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      final List<dynamic> list = data['waypoints'] is List
          ? data['waypoints'] as List
          : [];
      return list
          .map((json) => Waypoint.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Failed to import event FIT track: ${response.statusCode}',
      );
    }
  }
}
