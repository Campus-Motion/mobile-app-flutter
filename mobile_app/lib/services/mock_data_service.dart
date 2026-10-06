import 'dart:convert';
import 'package:http/http.dart' as http;

/// In-memory mock data store providing realistic backend responses
/// for developer demos and offline testing when the database is unavailable.
class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  static const Map<String, String> _jsonHeaders = {
    'content-type': 'application/json; charset=utf-8',
  };

  // Mock User
  final Map<String, dynamic> _mockUser = {
    'id': 1,
    'username': 'Robin.Doe',
    'email': 'robin.doe@epfl.ch',
    'photo_url': null,
    'role': 'student',
    'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
  };

  // Mock User Preferences
  final Map<String, dynamic> _mockPreferences = {
    'user_id': 1,
    'preferred_sports': ['running', 'trail', 'cycling'],
    'intensity': 'moderate',
    'goal': 'stay_active',
    'level': 'intermediate',
    'open_to_groups': true,
    'open_to_new_sports': true,
    'max_distance_km': 15.0,
  };

  // Mock Health Record (GDPR Article 9 encrypted payload compliant)
  Map<String, dynamic>? _mockHealth = {
    'born': '2002-04-12',
    'weight_kg': 68.5,
    'height_cm': 178.0,
    'consent_given_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
    'retain_until': DateTime.now().add(const Duration(days: 700)).toIso8601String(),
  };

  // Mock Campus News
  final List<Map<String, dynamic>> _mockNews = [
    {
      'id': 1,
      'title': 'Welcome to Campus Motion 2026!',
      'body': 'Explore the fitness trails connecting EPFL and UNIL, participate in community sports events, and track your workouts safely with end-to-end privacy.',
      'photo_url': null,
      'author_id': 1,
      'is_published': true,
      'published_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    },
    {
      'id': 2,
      'title': 'Autumn Lake-to-Campus Trail Challenge',
      'body': 'The annual lakefront trail challenge is now open. Complete the 5 checkpoints from Dorigny to Rolex Learning Center to claim your finisher badge.',
      'photo_url': null,
      'author_id': 1,
      'is_published': true,
      'published_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
    },
  ];

  // Mock Campus Events
  final List<Map<String, dynamic>> _mockEvents = [
    {
      'id': 101,
      'title': 'Sunset Lake Trail Run',
      'body': 'Join students for a relaxed 5km evening jog along Lake Geneva starting from Centre Sportif Dorigny.',
      'start_time': DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
      'end_time': DateTime.now().add(const Duration(hours: 5)).toIso8601String(),
      'distance_m': 5000.0,
      'participant_count': 9,
      'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
    },
    {
      'id': 102,
      'title': 'Morning Campus Interval Training',
      'body': 'Sprint intervals and mobility drill session on the athletic track. Suitable for all fitness levels.',
      'start_time': DateTime.now().add(const Duration(days: 1, hours: 2)).toIso8601String(),
      'end_time': DateTime.now().add(const Duration(days: 1, hours: 3)).toIso8601String(),
      'distance_m': 3500.0,
      'participant_count': 6,
      'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    },
    {
      'id': 103,
      'title': 'Dorigny to Morges Group Ride',
      'body': 'Scenic road cycling along the lakefront route. Bring your bike and helmet!',
      'start_time': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      'end_time': DateTime.now().add(const Duration(days: 3, hours: 2)).toIso8601String(),
      'distance_m': 22000.0,
      'participant_count': 14,
      'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
  ];

  // Mock Activities
  final List<Map<String, dynamic>> _mockActivities = [
    {
      'id': 201,
      'title': 'Morning Campus Run',
      'type': 'run',
      'user_id': 1,
      'is_public': true,
      'duration': 34.5,
      'body': 'Nice 6.2km loop through EPFL Innovation Park down to the lake shores.',
      'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
    {
      'id': 202,
      'title': 'Dorigny Lakefront Cycle',
      'type': 'cycle',
      'user_id': 1,
      'is_public': true,
      'duration': 48.0,
      'body': 'Recovery ride between classes along the lakeside bike path.',
      'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
    },
    {
      'id': 203,
      'title': 'Campus Trail Walk',
      'type': 'walk',
      'user_id': 1,
      'is_public': false,
      'duration': 25.0,
      'body': 'Walking the fitness checkpoints around Rolex Learning Center.',
      'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
    },
  ];

  // Mock Followers & Following
  final List<Map<String, dynamic>> _mockFollowers = [
    {
      'id': 2,
      'username': 'Camille.B',
      'email': 'camille.b@epfl.ch',
      'role': 'student',
      'created_at': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
    },
    {
      'id': 3,
      'username': 'Marc.V',
      'email': 'marc.v@unil.ch',
      'role': 'student',
      'created_at': DateTime.now().subtract(const Duration(days: 18)).toIso8601String(),
    },
  ];

  final List<Map<String, dynamic>> _mockFollowing = [
    {
      'id': 4,
      'username': 'Sarah.L',
      'email': 'sarah.l@epfl.ch',
      'role': 'student',
      'created_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
    },
  ];

  final Map<int, List<Map<String, dynamic>>> _mockEventParticipants = {
    101: [
      {
        'id': 1,
        'username': 'Robin.Doe',
        'email': 'robin.doe@epfl.ch',
        'role': 'student',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 2,
        'username': 'Camille.B',
        'email': 'camille.b@epfl.ch',
        'role': 'student',
        'created_at': DateTime.now().toIso8601String(),
      },
    ],
    102: [
      {
        'id': 2,
        'username': 'Camille.B',
        'email': 'camille.b@epfl.ch',
        'role': 'student',
        'created_at': DateTime.now().toIso8601String(),
      },
    ],
    103: [
      {
        'id': 3,
        'username': 'Marc.V',
        'email': 'marc.v@unil.ch',
        'role': 'student',
        'created_at': DateTime.now().toIso8601String(),
      },
    ],
  };

  /// Handles GET requests
  http.Response handleGet(String path) {
    final uri = Uri.parse(path.startsWith('/') ? path : '/$path');
    final cleanPath = uri.path;

    if (cleanPath == '/users/me') {
      return http.Response(json.encode(_mockUser), 200, headers: _jsonHeaders);
    }

    if (cleanPath == '/users/me/preferences') {
      return http.Response(json.encode(_mockPreferences), 200, headers: _jsonHeaders);
    }

    if (cleanPath == '/health') {
      if (_mockHealth == null) {
        return http.Response(json.encode({'message': 'No health data found'}), 404, headers: _jsonHeaders);
      }
      return http.Response(json.encode(_mockHealth), 200, headers: _jsonHeaders);
    }

    if (cleanPath == '/news') {
      return http.Response(json.encode({'data': _mockNews}), 200, headers: _jsonHeaders);
    }

    if (cleanPath == '/events') {
      return http.Response(json.encode({'data': _mockEvents}), 200, headers: _jsonHeaders);
    }

    final eventParticipantsMatch = RegExp(r'^/events/(\d+)/participants$').firstMatch(cleanPath);
    if (eventParticipantsMatch != null) {
      final eventId = int.parse(eventParticipantsMatch.group(1)!);
      final participants = _mockEventParticipants[eventId] ?? [];
      return http.Response(json.encode({'data': participants}), 200, headers: _jsonHeaders);
    }

    final singleEventMatch = RegExp(r'^/events/(\d+)$').firstMatch(cleanPath);
    if (singleEventMatch != null) {
      final eventId = int.parse(singleEventMatch.group(1)!);
      final event = _mockEvents.firstWhere(
        (e) => e['id'] == eventId,
        orElse: () => _mockEvents.first,
      );
      return http.Response(json.encode(event), 200, headers: _jsonHeaders);
    }

    if (cleanPath == '/activities') {
      return http.Response(json.encode({'data': _mockActivities}), 200, headers: _jsonHeaders);
    }

    final singleActivityMatch = RegExp(r'^/activities/(\d+)$').firstMatch(cleanPath);
    if (singleActivityMatch != null) {
      final activityId = int.parse(singleActivityMatch.group(1)!);
      final activity = _mockActivities.firstWhere(
        (a) => a['id'] == activityId,
        orElse: () => _mockActivities.first,
      );
      return http.Response(json.encode(activity), 200, headers: _jsonHeaders);
    }

    final followersMatch = RegExp(r'^/users/(\d+)/followers$').firstMatch(cleanPath);
    if (followersMatch != null) {
      return http.Response(json.encode({'data': _mockFollowers}), 200, headers: _jsonHeaders);
    }

    final followingMatch = RegExp(r'^/users/(\d+)/following$').firstMatch(cleanPath);
    if (followingMatch != null) {
      return http.Response(json.encode({'data': _mockFollowing}), 200, headers: _jsonHeaders);
    }

    final singleUserMatch = RegExp(r'^/users/(\d+)$').firstMatch(cleanPath);
    if (singleUserMatch != null) {
      final userId = int.parse(singleUserMatch.group(1)!);
      if (userId == 1) {
        return http.Response(json.encode(_mockUser), 200, headers: _jsonHeaders);
      }
      final other = _mockFollowers.followedBy(_mockFollowing).firstWhere(
        (u) => u['id'] == userId,
        orElse: () => {
          'id': userId,
          'username': 'Student_$userId',
          'email': 'student$userId@epfl.ch',
          'role': 'student',
          'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        },
      );
      return http.Response(json.encode(other), 200, headers: _jsonHeaders);
    }

    return http.Response(json.encode({'data': []}), 200, headers: _jsonHeaders);
  }

  /// Handles POST requests
  http.Response handlePost(String path, dynamic body) {
    final uri = Uri.parse(path.startsWith('/') ? path : '/$path');
    final cleanPath = uri.path;

    if (cleanPath == '/auth/login') {
      return http.Response(json.encode({'access_token': 'mock-dev-jwt-token'}), 200, headers: _jsonHeaders);
    }

    if (cleanPath == '/auth/register') {
      return http.Response(json.encode({'message': 'Registration successful'}), 201, headers: _jsonHeaders);
    }

    if (cleanPath == '/auth/logout') {
      return http.Response(json.encode({'message': 'Logged out successfully'}), 200, headers: _jsonHeaders);
    }

    if (cleanPath == '/activities') {
      Map<String, dynamic> data = {};
      if (body is Map<String, dynamic>) {
        data = body;
      } else if (body is String) {
        data = json.decode(body);
      }

      final newId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final newActivity = {
        'id': newId,
        'title': data['title'] ?? 'Recorded Activity',
        'type': data['type'] ?? 'run',
        'user_id': 1,
        'is_public': data['is_public'] ?? false,
        'duration': data['duration'] != null ? double.tryParse(data['duration'].toString()) ?? 30.0 : 30.0,
        'body': data['body'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
      };
      _mockActivities.insert(0, newActivity);
      return http.Response(json.encode(newActivity), 201, headers: _jsonHeaders);
    }

    final eventParticipantsMatch = RegExp(r'^/events/(\d+)/participants$').firstMatch(cleanPath);
    if (eventParticipantsMatch != null) {
      final eventId = int.parse(eventParticipantsMatch.group(1)!);
      final list = _mockEventParticipants.putIfAbsent(eventId, () => []);
      if (!list.any((u) => u['id'] == 1)) {
        list.add(_mockUser);
        final ev = _mockEvents.firstWhere((e) => e['id'] == eventId, orElse: () => {});
        if (ev.isNotEmpty) {
          ev['participant_count'] = (ev['participant_count'] as int? ?? 0) + 1;
        }
      }
      return http.Response(json.encode({'message': 'Successfully joined event'}), 201, headers: _jsonHeaders);
    }

    final followMatch = RegExp(r'^/users/(\d+)/follow$').firstMatch(cleanPath);
    if (followMatch != null) {
      final targetId = int.parse(followMatch.group(1)!);
      if (!_mockFollowing.any((u) => u['id'] == targetId)) {
        _mockFollowing.add({
          'id': targetId,
          'username': 'Student_$targetId',
          'email': 'student$targetId@epfl.ch',
          'role': 'student',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      return http.Response(json.encode({'message': 'Followed user'}), 201, headers: _jsonHeaders);
    }

    if (cleanPath == '/health') {
      Map<String, dynamic> data = {};
      if (body is Map<String, dynamic>) {
        data = body;
      } else if (body is String) {
        data = json.decode(body);
      }
      _mockHealth = {
        'born': data['born'] ?? '2002-04-12',
        'weight_kg': data['weight_kg'] ?? 68.5,
        'height_cm': data['height_cm'] ?? 178.0,
        'consent_given_at': DateTime.now().toIso8601String(),
        'retain_until': DateTime.now().add(const Duration(days: 730)).toIso8601String(),
      };
      return http.Response(json.encode(_mockHealth), 201, headers: _jsonHeaders);
    }

    return http.Response(json.encode({'message': 'Created'}), 201, headers: _jsonHeaders);
  }

  /// Handles PUT requests
  http.Response handlePut(String path, dynamic body) {
    final uri = Uri.parse(path.startsWith('/') ? path : '/$path');
    final cleanPath = uri.path;

    Map<String, dynamic> data = {};
    if (body is Map<String, dynamic>) {
      data = body;
    } else if (body is String) {
      data = json.decode(body);
    }

    if (cleanPath == '/users/me') {
      if (data.containsKey('username')) _mockUser['username'] = data['username'];
      if (data.containsKey('email')) _mockUser['email'] = data['email'];
      return http.Response(json.encode(_mockUser), 200, headers: _jsonHeaders);
    }

    if (cleanPath == '/users/me/preferences') {
      _mockPreferences.addAll(data);
      return http.Response(json.encode(_mockPreferences), 200, headers: _jsonHeaders);
    }

    if (cleanPath == '/health') {
      if (_mockHealth != null) {
        _mockHealth!.addAll(data);
      }
      return http.Response(json.encode(_mockHealth), 200, headers: _jsonHeaders);
    }

    if (cleanPath == '/auth/password') {
      return http.Response(json.encode({'message': 'Password updated successfully'}), 200, headers: _jsonHeaders);
    }

    final singleActivityMatch = RegExp(r'^/activities/(\d+)$').firstMatch(cleanPath);
    if (singleActivityMatch != null) {
      final activityId = int.parse(singleActivityMatch.group(1)!);
      final idx = _mockActivities.indexWhere((a) => a['id'] == activityId);
      if (idx != -1) {
        _mockActivities[idx].addAll(data);
        return http.Response(json.encode(_mockActivities[idx]), 200, headers: _jsonHeaders);
      }
    }

    return http.Response(json.encode({'message': 'Updated'}), 200, headers: _jsonHeaders);
  }

  /// Handles DELETE requests
  http.Response handleDelete(String path) {
    final uri = Uri.parse(path.startsWith('/') ? path : '/$path');
    final cleanPath = uri.path;

    if (cleanPath == '/users/me') {
      _mockActivities.clear();
      return http.Response(json.encode({'message': 'Account deleted successfully'}), 200, headers: _jsonHeaders);
    }

    if (cleanPath == '/health') {
      _mockHealth = null;
      return http.Response(json.encode({'message': 'Health data deleted successfully'}), 200, headers: _jsonHeaders);
    }

    final eventParticipantsMatch = RegExp(r'^/events/(\d+)/participants$').firstMatch(cleanPath);
    if (eventParticipantsMatch != null) {
      final eventId = int.parse(eventParticipantsMatch.group(1)!);
      final list = _mockEventParticipants[eventId];
      if (list != null) {
        list.removeWhere((u) => u['id'] == 1);
        final ev = _mockEvents.firstWhere((e) => e['id'] == eventId, orElse: () => {});
        if (ev.isNotEmpty && (ev['participant_count'] as int? ?? 0) > 0) {
          ev['participant_count'] = (ev['participant_count'] as int) - 1;
        }
      }
      return http.Response(json.encode({'message': 'Left event'}), 200, headers: _jsonHeaders);
    }

    final followMatch = RegExp(r'^/users/(\d+)/follow$').firstMatch(cleanPath);
    if (followMatch != null) {
      final targetId = int.parse(followMatch.group(1)!);
      _mockFollowing.removeWhere((u) => u['id'] == targetId);
      return http.Response(json.encode({'message': 'Unfollowed user'}), 200, headers: _jsonHeaders);
    }

    final singleActivityMatch = RegExp(r'^/activities/(\d+)$').firstMatch(cleanPath);
    if (singleActivityMatch != null) {
      final activityId = int.parse(singleActivityMatch.group(1)!);
      _mockActivities.removeWhere((a) => a['id'] == activityId);
      return http.Response(json.encode({'message': 'Activity deleted'}), 200, headers: _jsonHeaders);
    }

    return http.Response(json.encode({'message': 'Deleted successfully'}), 200, headers: _jsonHeaders);
  }
}
