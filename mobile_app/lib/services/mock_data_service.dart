import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'fit_decoder.dart';

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
    'created_at': DateTime.now()
        .subtract(const Duration(days: 30))
        .toIso8601String(),
  };

  int get currentMockUserId => _mockUser['id'] as int;

  void setMockUserProfile({required int userId}) {
    if (userId == 2) {
      _mockUser
        ..['id'] = 2
        ..['username'] = 'Camille.B'
        ..['email'] = 'camille.b@epfl.ch'
        ..['photo_url'] = null
        ..['role'] = 'student';
    } else {
      _mockUser
        ..['id'] = 1
        ..['username'] = 'Robin.Doe'
        ..['email'] = 'robin.doe@epfl.ch'
        ..['photo_url'] = null
        ..['role'] = 'student';
    }
  }

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
    'consent_given_at': DateTime.now()
        .subtract(const Duration(days: 30))
        .toIso8601String(),
    'retain_until': DateTime.now()
        .add(const Duration(days: 700))
        .toIso8601String(),
  };

  // Mock Campus News
  final List<Map<String, dynamic>> _mockNews = [
    {
      'id': 1,
      'title': 'Welcome to Campus Motion 2026!',
      'body':
          'Explore the fitness trails connecting EPFL and UNIL, participate in community sports events, and track your workouts safely with end-to-end privacy.',
      'photo_url': null,
      'author_id': 1,
      'is_published': true,
      'published_at': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
      'created_at': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
    },
    {
      'id': 2,
      'title': 'Autumn Lake-to-Campus Trail Challenge',
      'body':
          'The annual lakefront trail challenge is now open. Complete the 5 checkpoints from Dorigny to Rolex Learning Center to claim your finisher badge.',
      'photo_url': null,
      'author_id': 1,
      'is_published': true,
      'published_at': DateTime.now()
          .subtract(const Duration(days: 5))
          .toIso8601String(),
      'created_at': DateTime.now()
          .subtract(const Duration(days: 5))
          .toIso8601String(),
    },
  ];

  // Mock Campus Events
  final List<Map<String, dynamic>> _mockEvents = [
    {
      'id': 101,
      'title': 'Sunset Lake Trail Run',
      'body':
          'Join students for a relaxed 5km evening jog along Lake Geneva starting from Centre Sportif Dorigny.',
      'start_time': DateTime.now()
          .add(const Duration(hours: 4))
          .toIso8601String(),
      'end_time': DateTime.now()
          .add(const Duration(hours: 5))
          .toIso8601String(),
      'distance_m': 5000.0,
      'participant_count': 9,
      'created_at': DateTime.now()
          .subtract(const Duration(days: 3))
          .toIso8601String(),
    },
    {
      'id': 102,
      'title': 'Morning Campus Interval Training',
      'body':
          'Sprint intervals and mobility drill session on the athletic track. Suitable for all fitness levels.',
      'start_time': DateTime.now()
          .add(const Duration(days: 1, hours: 2))
          .toIso8601String(),
      'end_time': DateTime.now()
          .add(const Duration(days: 1, hours: 3))
          .toIso8601String(),
      'distance_m': 3500.0,
      'participant_count': 6,
      'created_at': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
    },
    {
      'id': 103,
      'title': 'Dorigny to Morges Group Ride',
      'body':
          'Scenic road cycling along the lakefront route. Bring your bike and helmet!',
      'start_time': DateTime.now()
          .add(const Duration(days: 3))
          .toIso8601String(),
      'end_time': DateTime.now()
          .add(const Duration(days: 3, hours: 2))
          .toIso8601String(),
      'distance_m': 22000.0,
      'participant_count': 14,
      'created_at': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
    },
    {
      'id': 104,
      'title': 'Past Campus Welcome Run',
      'body': 'Completed 5km campus welcome run.',
      'user_id': 1,
      'start_time': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
      'end_time': DateTime.now()
          .subtract(const Duration(days: 2, hours: -1))
          .toIso8601String(),
      'distance_m': 5000.0,
      'participant_count': 18,
      'created_at': DateTime.now()
          .subtract(const Duration(days: 5))
          .toIso8601String(),
    },
    {
      'id': 105,
      'title': 'Lakeside Track Recovery Session',
      'body': 'Light recovery session by the lake track.',
      'user_id': 3,
      'start_time': DateTime.now()
          .subtract(const Duration(days: 4))
          .toIso8601String(),
      'end_time': DateTime.now()
          .subtract(const Duration(days: 4, hours: -1))
          .toIso8601String(),
      'distance_m': 4000.0,
      'participant_count': 7,
      'created_at': DateTime.now()
          .subtract(const Duration(days: 6))
          .toIso8601String(),
    },
  ];

  // Mock Activities (2 instances per discipline: run, cycle, walk, hike)
  static List<Map<String, dynamic>> _buildInitialActivities() => [
    {
      'id': 201,
      'title': 'Morning Campus Run',
      'type': 'run',
      'user_id': 1,
      'is_public': true,
      'duration': 34.5,
      'distance_km': 6.2,
      'has_fit': true,
      'body':
          'Nice 6.2km loop through EPFL Innovation Park down to the lake shores.',
      'created_at': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
    },
    {
      'id': 202,
      'title': 'Evening Innovation Park Run',
      'type': 'run',
      'user_id': 1,
      'is_public': true,
      'duration': 28.0,
      'distance_km': 5.1,
      'has_fit': true,
      'body': 'Tempo run crossing the central campus avenue toward Dorigny.',
      'created_at': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
    },
    {
      'id': 203,
      'title': 'Dorigny Lakefront Cycle',
      'type': 'cycle',
      'user_id': 1,
      'is_public': true,
      'duration': 48.0,
      'distance_km': 16.0,
      'has_fit': true,
      'body': 'Recovery ride between classes along the lakeside bike path.',
      'created_at': DateTime.now()
          .subtract(const Duration(days: 3))
          .toIso8601String(),
    },
    {
      'id': 204,
      'title': 'St-Sulpice Campus Ride',
      'type': 'cycle',
      'user_id': 1,
      'is_public': true,
      'duration': 42.0,
      'distance_km': 14.2,
      'has_fit': true,
      'body': 'Afternoon ride from campus sharing the lakeside section.',
      'created_at': DateTime.now()
          .subtract(const Duration(days: 4))
          .toIso8601String(),
    },
    {
      'id': 205,
      'title': 'Campus Trail Walk',
      'type': 'walk',
      'user_id': 1,
      'is_public': false,
      'duration': 25.0,
      'distance_km': 2.1,
      'has_fit': true,
      'body': 'Walking the fitness checkpoints around Rolex Learning Center.',
      'created_at': DateTime.now()
          .subtract(const Duration(days: 5))
          .toIso8601String(),
    },
    {
      'id': 206,
      'title': 'Lakeside Walk',
      'type': 'walk',
      'user_id': 1,
      'is_public': true,
      'duration': 30.0,
      'distance_km': 2.5,
      'has_fit': true,
      'body': 'Gentle stroll along Lake Geneva crossing the esplanade.',
      'created_at': DateTime.now()
          .subtract(const Duration(days: 6))
          .toIso8601String(),
    },
    {
      'id': 207,
      'title': 'Campus Hill Hike',
      'type': 'hike',
      'user_id': 1,
      'is_public': true,
      'duration': 75.0,
      'distance_km': 6.8,
      'has_fit': true,
      'body': 'Scenic hike towards Mount Dorigny view.',
      'created_at': DateTime.now()
          .subtract(const Duration(days: 7))
          .toIso8601String(),
    },
    {
      'id': 208,
      'title': 'Chamberonne Forest Hike',
      'type': 'hike',
      'user_id': 1,
      'is_public': true,
      'duration': 65.0,
      'distance_km': 5.9,
      'has_fit': true,
      'body': 'Forest loop crossing the northern hill ridge.',
      'created_at': DateTime.now()
          .subtract(const Duration(days: 8))
          .toIso8601String(),
    },
  ];

  late final List<Map<String, dynamic>> _mockActivities =
      _buildInitialActivities();

  // Default fallback Mock Waypoints (Run 1)
  final List<Map<String, dynamic>> _defaultMockWaypoints = [
    {
      'id': 1,
      'sequence_order': 0,
      'latitude': 46.5190,
      'longitude': 6.5660,
      'altitude_m': 395.0,
      'recorded_at': '2026-11-16T08:00:00Z',
    },
    {
      'id': 2,
      'sequence_order': 1,
      'latitude': 46.5205,
      'longitude': 6.5680,
      'altitude_m': 393.5,
      'recorded_at': '2026-11-16T08:00:55Z',
    },
    {
      'id': 3,
      'sequence_order': 2,
      'latitude': 46.5218,
      'longitude': 6.5725,
      'altitude_m': 388.0,
      'recorded_at': '2026-11-16T08:02:35Z',
    },
    {
      'id': 4,
      'sequence_order': 3,
      'latitude': 46.5195,
      'longitude': 6.5760,
      'altitude_m': 385.0,
      'recorded_at': '2026-11-16T08:04:30Z',
    },
    {
      'id': 5,
      'sequence_order': 4,
      'latitude': 46.5170,
      'longitude': 6.5720,
      'altitude_m': 390.0,
      'recorded_at': '2026-11-16T08:07:00Z',
    },
    {
      'id': 6,
      'sequence_order': 5,
      'latitude': 46.5160,
      'longitude': 6.5665,
      'altitude_m': 398.0,
      'recorded_at': '2026-11-16T08:10:00Z',
    },
    {
      'id': 7,
      'sequence_order': 6,
      'latitude': 46.5190,
      'longitude': 6.5660,
      'altitude_m': 395.0,
      'recorded_at': '2026-11-16T08:11:35Z',
    },
  ];

  Map<int, List<Map<String, dynamic>>> _buildInitialWaypoints() => {
    // Run 1 & Run 2: share the Innovation Park segment (46.5205,6.5680 -> 46.5218,6.5725 -> 46.5195,6.5760)
    201: List<Map<String, dynamic>>.from(_defaultMockWaypoints),
    202: [
      {
        'id': 21,
        'sequence_order': 0,
        'latitude': 46.5242,
        'longitude': 6.5655,
        'altitude_m': 405.0,
        'recorded_at': '2026-11-15T17:00:00Z',
      },
      {
        'id': 22,
        'sequence_order': 1,
        'latitude': 46.5205,
        'longitude': 6.5680,
        'altitude_m': 393.5,
        'recorded_at': '2026-11-15T17:02:00Z',
      },
      {
        'id': 23,
        'sequence_order': 2,
        'latitude': 46.5218,
        'longitude': 6.5725,
        'altitude_m': 388.0,
        'recorded_at': '2026-11-15T17:03:45Z',
      },
      {
        'id': 24,
        'sequence_order': 3,
        'latitude': 46.5195,
        'longitude': 6.5760,
        'altitude_m': 385.0,
        'recorded_at': '2026-11-15T17:05:30Z',
      },
      {
        'id': 25,
        'sequence_order': 4,
        'latitude': 46.5230,
        'longitude': 6.5795,
        'altitude_m': 396.0,
        'recorded_at': '2026-11-15T17:07:40Z',
      },
      {
        'id': 26,
        'sequence_order': 5,
        'latitude': 46.5252,
        'longitude': 6.5740,
        'altitude_m': 408.0,
        'recorded_at': '2026-11-15T17:09:30Z',
      },
    ],
    // Cycle 1 & Cycle 2: share the lakeside bike path (46.5152,6.5770 -> 46.5145,6.5650 -> 46.5135,6.5530)
    203: [
      {
        'id': 31,
        'sequence_order': 0,
        'latitude': 46.5148,
        'longitude': 6.5880,
        'altitude_m': 374.0,
        'recorded_at': '2026-11-14T14:00:00Z',
      },
      {
        'id': 32,
        'sequence_order': 1,
        'latitude': 46.5152,
        'longitude': 6.5770,
        'altitude_m': 375.0,
        'recorded_at': '2026-11-14T14:01:45Z',
      },
      {
        'id': 33,
        'sequence_order': 2,
        'latitude': 46.5145,
        'longitude': 6.5650,
        'altitude_m': 374.0,
        'recorded_at': '2026-11-14T14:03:20Z',
      },
      {
        'id': 34,
        'sequence_order': 3,
        'latitude': 46.5135,
        'longitude': 6.5530,
        'altitude_m': 373.5,
        'recorded_at': '2026-11-14T14:05:10Z',
      },
      {
        'id': 35,
        'sequence_order': 4,
        'latitude': 46.5120,
        'longitude': 6.5410,
        'altitude_m': 373.0,
        'recorded_at': '2026-11-14T14:07:15Z',
      },
    ],
    204: [
      {
        'id': 41,
        'sequence_order': 0,
        'latitude': 46.5215,
        'longitude': 6.5780,
        'altitude_m': 392.0,
        'recorded_at': '2026-11-13T16:00:00Z',
      },
      {
        'id': 42,
        'sequence_order': 1,
        'latitude': 46.5152,
        'longitude': 6.5770,
        'altitude_m': 375.0,
        'recorded_at': '2026-11-13T16:01:30Z',
      },
      {
        'id': 43,
        'sequence_order': 2,
        'latitude': 46.5145,
        'longitude': 6.5650,
        'altitude_m': 374.0,
        'recorded_at': '2026-11-13T16:03:10Z',
      },
      {
        'id': 44,
        'sequence_order': 3,
        'latitude': 46.5135,
        'longitude': 6.5530,
        'altitude_m': 373.5,
        'recorded_at': '2026-11-13T16:05:00Z',
      },
      {
        'id': 45,
        'sequence_order': 4,
        'latitude': 46.5205,
        'longitude': 6.5510,
        'altitude_m': 389.0,
        'recorded_at': '2026-11-13T16:07:10Z',
      },
    ],
    // Walk 1 & Walk 2: share the central esplanade walkway (46.5192,6.5675 -> 46.5202,6.5715 -> 46.5212,6.5755)
    205: [
      {
        'id': 51,
        'sequence_order': 0,
        'latitude': 46.5175,
        'longitude': 6.5640,
        'altitude_m': 392.0,
        'recorded_at': '2026-11-12T12:00:00Z',
      },
      {
        'id': 52,
        'sequence_order': 1,
        'latitude': 46.5192,
        'longitude': 6.5675,
        'altitude_m': 395.0,
        'recorded_at': '2026-11-12T12:04:00Z',
      },
      {
        'id': 53,
        'sequence_order': 2,
        'latitude': 46.5202,
        'longitude': 6.5715,
        'altitude_m': 391.0,
        'recorded_at': '2026-11-12T12:08:30Z',
      },
      {
        'id': 54,
        'sequence_order': 3,
        'latitude': 46.5212,
        'longitude': 6.5755,
        'altitude_m': 388.0,
        'recorded_at': '2026-11-12T12:13:30Z',
      },
      {
        'id': 55,
        'sequence_order': 4,
        'latitude': 46.5228,
        'longitude': 6.5785,
        'altitude_m': 390.0,
        'recorded_at': '2026-11-12T12:18:00Z',
      },
    ],
    206: [
      {
        'id': 61,
        'sequence_order': 0,
        'latitude': 46.5225,
        'longitude': 6.5655,
        'altitude_m': 399.0,
        'recorded_at': '2026-11-11T12:30:00Z',
      },
      {
        'id': 62,
        'sequence_order': 1,
        'latitude': 46.5192,
        'longitude': 6.5675,
        'altitude_m': 395.0,
        'recorded_at': '2026-11-11T12:35:00Z',
      },
      {
        'id': 63,
        'sequence_order': 2,
        'latitude': 46.5202,
        'longitude': 6.5715,
        'altitude_m': 391.0,
        'recorded_at': '2026-11-11T12:39:40Z',
      },
      {
        'id': 64,
        'sequence_order': 3,
        'latitude': 46.5212,
        'longitude': 6.5755,
        'altitude_m': 388.0,
        'recorded_at': '2026-11-11T12:44:30Z',
      },
      {
        'id': 65,
        'sequence_order': 4,
        'latitude': 46.5170,
        'longitude': 6.5765,
        'altitude_m': 381.0,
        'recorded_at': '2026-11-11T12:50:30Z',
      },
    ],
    // Hike 1 & Hike 2: share the northern hill ridge (46.5280,6.5630 -> 46.5305,6.5685)
    207: [
      {
        'id': 71,
        'sequence_order': 0,
        'latitude': 46.5255,
        'longitude': 6.5580,
        'altitude_m': 410.0,
        'recorded_at': '2026-11-10T09:00:00Z',
      },
      {
        'id': 72,
        'sequence_order': 1,
        'latitude': 46.5280,
        'longitude': 6.5630,
        'altitude_m': 428.0,
        'recorded_at': '2026-11-10T09:06:30Z',
      },
      {
        'id': 73,
        'sequence_order': 2,
        'latitude': 46.5305,
        'longitude': 6.5685,
        'altitude_m': 445.0,
        'recorded_at': '2026-11-10T09:13:30Z',
      },
      {
        'id': 74,
        'sequence_order': 3,
        'latitude': 46.5335,
        'longitude': 6.5745,
        'altitude_m': 462.0,
        'recorded_at': '2026-11-10T09:21:30Z',
      },
      {
        'id': 75,
        'sequence_order': 4,
        'latitude': 46.5360,
        'longitude': 6.5790,
        'altitude_m': 478.0,
        'recorded_at': '2026-11-10T09:28:00Z',
      },
    ],
    208: [
      {
        'id': 81,
        'sequence_order': 0,
        'latitude': 46.5250,
        'longitude': 6.5720,
        'altitude_m': 412.0,
        'recorded_at': '2026-11-09T10:00:00Z',
      },
      {
        'id': 82,
        'sequence_order': 1,
        'latitude': 46.5280,
        'longitude': 6.5630,
        'altitude_m': 428.0,
        'recorded_at': '2026-11-09T10:09:30Z',
      },
      {
        'id': 83,
        'sequence_order': 2,
        'latitude': 46.5305,
        'longitude': 6.5685,
        'altitude_m': 445.0,
        'recorded_at': '2026-11-09T10:16:30Z',
      },
      {
        'id': 84,
        'sequence_order': 3,
        'latitude': 46.5350,
        'longitude': 6.5620,
        'altitude_m': 468.0,
        'recorded_at': '2026-11-09T10:25:30Z',
      },
    ],
  };

  late final Map<int, List<Map<String, dynamic>>> _mockWaypoints =
      _buildInitialWaypoints();

  final Map<int, List<Map<String, dynamic>>> _mockEventWaypoints = {};

  // Mock Followers & Following
  final List<Map<String, dynamic>> _mockFollowers = [
    {
      'id': 2,
      'username': 'Camille.B',
      'email': 'camille.b@epfl.ch',
      'role': 'student',
      'created_at': DateTime.now()
          .subtract(const Duration(days: 20))
          .toIso8601String(),
    },
    {
      'id': 3,
      'username': 'Marc.V',
      'email': 'marc.v@unil.ch',
      'role': 'student',
      'created_at': DateTime.now()
          .subtract(const Duration(days: 18))
          .toIso8601String(),
    },
  ];

  final List<Map<String, dynamic>> _mockFollowing = [
    {
      'id': 4,
      'username': 'Sarah.L',
      'email': 'sarah.l@epfl.ch',
      'role': 'student',
      'created_at': DateTime.now()
          .subtract(const Duration(days: 15))
          .toIso8601String(),
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
    104: [
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
    105: [
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
  http.Response handleGet(String path, {Map<String, String>? headers}) {
    final uri = Uri.parse(path.startsWith('/') ? path : '/$path');
    final cleanPath = uri.path;

    if (cleanPath == '/activities/export') {
      return http.Response(
        json.encode([
          for (final activity in _mockActivities)
            if (activity['user_id'] == _mockUser['id'])
              {...activity, 'waypoints': <dynamic>[]},
        ]),
        200,
        headers: _jsonHeaders,
      );
    }

    if (cleanPath == '/activities/heatmap') {
      // Synthetic route rendered locally; no personal GPS data or network tiles.
      return http.Response(
        json.encode({
          'image':
              'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAAAoCAYAAABOzvzpAAAHv0lEQVR4nO1ZS6wcVxE9'
              'VffT83kfO5EiWYqUxFjEmAVC2QCLBCkS8gayISxAEUhI3sRRYrFkwYY9LxgWBCE+EopEEOwQQnxXWSXLYAdDEstSgB'
              'B/3kz3dPe9VcXi9rz37ERBz++9bJgj9fTMqKfr1umqU1V3gBVWWGGFFVZY4f8VdJQ3P3fixGTqnC1iXK+inoUZG0DO'
              'OQCAmu3YZyKDCAQAEUnX82/HfT+rReiFt99ujmqNh0rAM6dOVRK6U5H85xzhNIEeY8CYqAJwPwFEoL1W99o3WHkxwA'
              'BcU7NOATLYn7PoJc32u4tXrr52mGs+FAK++sADo2MTesIxP+0Jpz3xvYFIPHNmIjiGsZFQcb8YvdPy4LUBMDMomRMF'
              'iRmyqk+mLiveUbNfidgfty6/8cvDWPuBCbhw5iOn2Ox7wdNnK3YITLki1sAMzwRHBB4OB4D4TuOE4eEDAEwBAaBmkO'
              'HIakiq6E25Ex31Kk1S+3Hq3bcvXrnyzkHWfyACnvvYg18KTBcr5zcnjtPIOYvMqJgRHcEzwRPBMYFRzssUuD0LBgKG'
              'FBA16HDOZkhq6MXQqaITQatKC9G1VvT3Ocv55y+/eflDJ+CZhx/64tjzD8eeq6nzeewcJt6h8oyKCZVjeB/gQgQHD/'
              'Ye5BzADkSuWKbBvJXnbyqAKkwyNGdoypC+Q5KMThStKNqsWIigFkWT02gh9uYsuc+88Prr//nQCPj6mfvvOU7VyxPv'
              'Hlh3rp94j2l0mDjG2HnE0Rh+OoEbT+BGI/gYQT6CnAN5BhEX599DgAKi0JxhuUfuOkjbQhY10rxG37dosqIRQd0L5i'
              'KY51QtRP7w7ly//NO33rq5X1/83RCwifh8ZHpozNyOvcNaKM6vVRFhfRNhYxNxbR1+MgGPJnAxgmIoUcAeYAbRHdxb'
              'iQBTgeYE6xOk7yCLBrmu4SYzuNlNuO3twpuipIn5ThRn753yUwAu7teXfUfA+Y8/+Ikx+E9rwccNH3QjeKxHh7Uqoj'
              'p2HPH4vag2jyFMN+DWJvDjCVxVgUMAD1EAYmCpB1jWPxvCvxCgqUdu20LAvEbavoV2+wbS9XfRbt/CrEvYToJ5ytjO'
              '2ddJrnQ9Pb5fUdx3BHjDo97RWmTXRmZUnjFyjDhdQ9g8VpzfPI64sYmwNoUblTTgGEE+lDRgVyJgTwqYWYmAJQFdB9'
              '91yE0NDgFgLkKZBdonjGSO3gy9MAJzZpaH4fMZAH85UgIYdNYxWSBCYEIgIIQAHk8RJ2vw03WE9XWE9TWE6TrcZAI3'
              'GoMHMSTnwewGDdhzYzOoKExSEb+qg7SLgSzARKG5h7YN8niCsGjgCXA7lQbw4E8eOQEAGaPU9Z0S5wI4xuJkVcHHCF'
              'eNwaMKrhrDjSpwqOB8AHkHYgZoVwfMSgvEojDxEJeW1REQgaYRXDUCxwoulmhi5+CIdg4GwcgeB7B1pAQwAL7j4YGo'
              'OMPDt0vndtSeAR4OoiKCzLu/NYOpgdhgWq6hnWt339OgHeX+vNtVLpcB0/36s28CDEZiVjo1ADqot2aB5ZLDkhM0Z3'
              'BK0JBBKRVnDGB1INXizN77DiIokgcRHM59LqGfh885lzRRgVrpGM3KBKHAjSMnQEH/1CUBqsjGkJSgXQNpG8iihlQR'
              '2YfBaQNUoCmBfVdE0Ln39gEGmOwVwRYyiGCqG0hTQxcNcttA2xYigoyhVTaDKghqLx45AWb2YlY81ZlhpKVN7XKGr2'
              't01awoPXERtZyhfQfXtuAQQLH0Ae+rAaYwVZhmWJ8hfQ/tWqSmQZ7PkLZvoZ9tI81myE2DTgQpF/vJlMVsRqT7ngv2'
              'TcCM0qtO46Ve9aOtah+SwBPBNw2IrhftUoGmHrJYIDVjuKVA7pTBIY+XpBYWCgHLCOj7oRFaINdzpNk2uls3kG7eRN'
              'O3WIhiIYpWFb1oFMOvty5dffXICfjRa9euXzh98ludyE8CgQORcRKAAKvn0CyQdoE8r0s7XI3BVSwRwMt5YCmSexkY'
              'UkCHUtgnSNdBugVyXSPNZ0jzORZdi0YUTRK0ImhFfK9W52zf3a8vwAGGoQtnTv5s5PgrU+/r6TAITYamaOQdQhzBjS'
              'q4WIFjVdpg7wHHYHq/VrjkM6SIaYmCDtK1kLZF33dY5PLEmyRosqDO2dUi1Il8beuvb/7ibvy4q1kAAHLP57soGwCe'
              'UGgtZprVoXeGVhQxZfhFg+AYjhjs/G3l7H1Ggd00UIVKhqgiqZRxWA1tNnQqaLOgFvEL0a7L9v2tS3fnPHDA/YBnTp'
              '3a8FG+GYjPjTxPRsx9ZGcVEzwzIhMcMxwtewe6bQq+fT+sQJd7AlbeJ9XdDRFVtKrcivpO9GYy/cbWa2/8/CA+HMqW'
              '2LMPP/gF7/g5z/ypwIiRXR+Y1BOpo0IAgYbul/7HlpiVyjmQUEqtuqRGvWrIateT6qua5emtv139x0HXfmibouceeS'
              'TE+sbnA9ujjuisZ9ok0H2OyJgAB0pLAj4ISwIEFtQAMSM1+5eo3hKj35DZD+bTe9544ZVX0mGs+0i2xc+dODEZbY5P'
              'EuunHZGx8jGFPEml/aP3KuCwGBumAjNhuJeU9aaYkSm/7Ob9379z7drisNd6pP8L7MWTgPv30t5j+MCZ7T7AXip7oy'
              'ussMIKK6ywwtHhv+Zgokqqx1XgAAAAAElFTkSuQmCC',
          'bounds': [
            [46.49981135346308, 6.49975927950072],
            [46.5001886458824, 6.500646691911085],
          ],
          'runs': 1,
          'points': 5,
          'pixel_m': 0.5,
          'saturation': 1.0,
        }),
        200,
        headers: _jsonHeaders,
      );
    }

    if (cleanPath == '/users/me') {
      final authHeader = headers?['Authorization'];
      if (authHeader != null &&
          (authHeader == 'Bearer expired' ||
              authHeader == 'Bearer rejected' ||
              authHeader == 'Bearer invalid')) {
        return http.Response(
          json.encode({'message': 'Invalid or expired token'}),
          401,
          headers: _jsonHeaders,
        );
      }
      return http.Response(json.encode(_mockUser), 200, headers: _jsonHeaders);
    }

    if (cleanPath == '/users/me/preferences') {
      return http.Response(
        json.encode(_mockPreferences),
        200,
        headers: _jsonHeaders,
      );
    }

    if (cleanPath == '/health') {
      if (_mockHealth == null) {
        return http.Response(
          json.encode({'message': 'No health data found'}),
          404,
          headers: _jsonHeaders,
        );
      }
      return http.Response(
        json.encode(_mockHealth),
        200,
        headers: _jsonHeaders,
      );
    }

    if (cleanPath == '/news') {
      return http.Response(
        json.encode({'data': _mockNews}),
        200,
        headers: _jsonHeaders,
      );
    }

    if (cleanPath == '/events') {
      var events = List<Map<String, dynamic>>.from(_mockEvents);
      final afterParam = uri.queryParameters['after'];
      if (afterParam != null) {
        final afterDate = DateTime.tryParse(afterParam);
        if (afterDate != null) {
          events = events.where((e) {
            final start = DateTime.tryParse(e['start_time'] as String? ?? '');
            return start != null && start.isAfter(afterDate);
          }).toList();
        }
      }
      final limitParam = uri.queryParameters['limit'];
      if (limitParam != null) {
        final limit = int.tryParse(limitParam);
        if (limit != null && events.length > limit) {
          events = events.sublist(0, limit);
        }
      }
      return http.Response(
        json.encode({'data': events}),
        200,
        headers: _jsonHeaders,
      );
    }

    final eventParticipantsMatch = RegExp(
      r'^/events/(\d+)/participants$',
    ).firstMatch(cleanPath);
    if (eventParticipantsMatch != null) {
      final eventId = int.parse(eventParticipantsMatch.group(1)!);
      final participants = _mockEventParticipants[eventId] ?? [];
      return http.Response(
        json.encode({'data': participants}),
        200,
        headers: _jsonHeaders,
      );
    }

    final singleEventMatch = RegExp(r'^/events/(\d+)$').firstMatch(cleanPath);
    if (singleEventMatch != null) {
      final eventId = int.parse(singleEventMatch.group(1)!);
      final index = _mockEvents.indexWhere((e) => e['id'] == eventId);
      if (index != -1) {
        return http.Response(
          json.encode(_mockEvents[index]),
          200,
          headers: _jsonHeaders,
        );
      }
      return http.Response(
        json.encode({'message': 'Event not found'}),
        404,
        headers: _jsonHeaders,
      );
    }

    if (cleanPath == '/activities') {
      var activities = List<Map<String, dynamic>>.from(_mockActivities);
      final typeParam = uri.queryParameters['type'];
      if (typeParam != null && typeParam.trim().isNotEmpty) {
        final targetType = typeParam.toLowerCase().trim();
        activities = activities
            .where(
              (a) =>
                  (a['type'] as String? ?? '').toLowerCase().trim() ==
                  targetType,
            )
            .toList();
      }
      final publicParam = uri.queryParameters['public'];
      if (publicParam != null) {
        final isPublic = publicParam.toLowerCase() == 'true';
        activities = activities
            .where((a) => (a['is_public'] as bool? ?? false) == isPublic)
            .toList();
      } else {
        final currentUserId = _mockUser['id'];
        activities = activities
            .where((a) => a['user_id'] == currentUserId)
            .toList();
      }
      final limitParam = uri.queryParameters['limit'];
      if (limitParam != null) {
        final limit = int.tryParse(limitParam);
        if (limit != null && activities.length > limit) {
          activities = activities.sublist(0, limit);
        }
      }
      return http.Response(
        json.encode({'data': activities}),
        200,
        headers: _jsonHeaders,
      );
    }

    final singleActivityMatch = RegExp(
      r'^/activities/(\d+)$',
    ).firstMatch(cleanPath);
    if (singleActivityMatch != null) {
      final activityId = int.parse(singleActivityMatch.group(1)!);
      final activity = _mockActivities.firstWhere(
        (a) => a['id'] == activityId,
        orElse: () => _mockActivities.first,
      );
      return http.Response(json.encode(activity), 200, headers: _jsonHeaders);
    }

    final waypointsMatch = RegExp(
      r'^/activities/(\d+)/waypoints$',
    ).firstMatch(cleanPath);
    if (waypointsMatch != null) {
      final activityId = int.parse(waypointsMatch.group(1)!);
      final waypoints = _mockWaypoints[activityId] ?? [];
      return http.Response(json.encode(waypoints), 200, headers: _jsonHeaders);
    }

    final eventWaypointsMatch = RegExp(
      r'^/events/(\d+)/waypoints$',
    ).firstMatch(cleanPath);
    if (eventWaypointsMatch != null) {
      final eventId = int.parse(eventWaypointsMatch.group(1)!);
      final waypoints = _mockEventWaypoints[eventId] ?? [];
      return http.Response(json.encode(waypoints), 200, headers: _jsonHeaders);
    }

    if (cleanPath == '/users/search') {
      final query = (uri.queryParameters['q'] ?? '').trim().toLowerCase();
      if (query.length < 2) {
        return http.Response(
          json.encode({'message': 'q must be at least 2 characters'}),
          400,
          headers: _jsonHeaders,
        );
      }
      final matches = <int, Map<String, dynamic>>{};
      for (final user in _mockFollowers.followedBy(_mockFollowing)) {
        final username = (user['username'] as String).toLowerCase();
        if (user['id'] != _mockUser['id'] && username.startsWith(query)) {
          // Public fields only, like the real endpoint: no email.
          matches[user['id'] as int] = Map.of(user)..remove('email');
        }
      }
      final data = matches.values.take(20).toList();
      return http.Response(
        json.encode({
          'data': data,
          'meta': {'total': data.length, 'limit': 20},
        }),
        200,
        headers: _jsonHeaders,
      );
    }

    final followersMatch = RegExp(
      r'^/users/(\d+)/followers$',
    ).firstMatch(cleanPath);
    if (followersMatch != null) {
      return http.Response(
        json.encode({'data': _mockFollowers}),
        200,
        headers: _jsonHeaders,
      );
    }

    final followingMatch = RegExp(
      r'^/users/(\d+)/following$',
    ).firstMatch(cleanPath);
    if (followingMatch != null) {
      return http.Response(
        json.encode({'data': _mockFollowing}),
        200,
        headers: _jsonHeaders,
      );
    }

    final singleUserMatch = RegExp(r'^/users/(\d+)$').firstMatch(cleanPath);
    if (singleUserMatch != null) {
      final userId = int.parse(singleUserMatch.group(1)!);
      if (userId == 1) {
        return http.Response(
          json.encode(_mockUser),
          200,
          headers: _jsonHeaders,
        );
      }
      final other = _mockFollowers
          .followedBy(_mockFollowing)
          .firstWhere(
            (u) => u['id'] == userId,
            orElse: () => {
              'id': userId,
              'username': 'Student_$userId',
              'email': 'student$userId@epfl.ch',
              'role': 'student',
              'created_at': DateTime.now()
                  .subtract(const Duration(days: 10))
                  .toIso8601String(),
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
      return http.Response(
        json.encode({'access_token': 'mock-dev-jwt-token'}),
        200,
        headers: _jsonHeaders,
      );
    }

    if (cleanPath == '/auth/register') {
      return http.Response(
        json.encode({'message': 'Registration successful'}),
        201,
        headers: _jsonHeaders,
      );
    }

    if (cleanPath == '/auth/logout') {
      return http.Response(
        json.encode({'message': 'Logged out successfully'}),
        200,
        headers: _jsonHeaders,
      );
    }

    if (cleanPath == '/activities') {
      Map<String, dynamic> data = {};
      if (body is Map<String, dynamic>) {
        data = body;
      } else if (body is String) {
        data = json.decode(body);
      }

      double? parsedDistanceKm;
      if (data['distance_km'] != null) {
        parsedDistanceKm = double.tryParse(data['distance_km'].toString());
      } else if (data['distance_m'] != null) {
        final meters = double.tryParse(data['distance_m'].toString());
        if (meters != null) {
          parsedDistanceKm = meters / 1000.0;
        }
      }

      final newId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final newActivity = {
        'id': newId,
        'title': data['title'] ?? 'Recorded Activity',
        'type': data['type'] ?? 'run',
        'user_id': _mockUser['id'],
        'is_public': data['is_public'] ?? false,
        'duration': data['duration'] != null
            ? double.tryParse(data['duration'].toString()) ?? 30.0
            : 30.0,
        'distance_km': ?parsedDistanceKm,
        'body': data['body'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
      };
      _mockActivities.insert(0, newActivity);
      return http.Response(
        json.encode(newActivity),
        201,
        headers: _jsonHeaders,
      );
    }

    final postWaypointsMatch = RegExp(
      r'^/activities/(\d+)/waypoints$',
    ).firstMatch(cleanPath);
    if (postWaypointsMatch != null) {
      final activityId = int.parse(postWaypointsMatch.group(1)!);
      Map<String, dynamic> data = {};
      if (body is Map<String, dynamic>) {
        data = body;
      } else if (body is String) {
        data = json.decode(body);
      }
      final wpList = data['waypoints'] is List
          ? (data['waypoints'] as List)
                .map((w) => Map<String, dynamic>.from(w as Map))
                .toList()
          : <Map<String, dynamic>>[];
      _mockWaypoints[activityId] = wpList;
      return http.Response(
        json.encode({'inserted': wpList.length, 'waypoints': wpList}),
        201,
        headers: _jsonHeaders,
      );
    }

    final eventParticipantsMatch = RegExp(
      r'^/events/(\d+)/participants$',
    ).firstMatch(cleanPath);
    if (eventParticipantsMatch != null) {
      final eventId = int.parse(eventParticipantsMatch.group(1)!);
      final list = _mockEventParticipants.putIfAbsent(eventId, () => []);
      final currentId = _mockUser['id'];
      if (!list.any((u) => u['id'] == currentId)) {
        list.add(Map<String, dynamic>.from(_mockUser));
        final ev = _mockEvents.firstWhere(
          (e) => e['id'] == eventId,
          orElse: () => {},
        );
        if (ev.isNotEmpty) {
          ev['participant_count'] = (ev['participant_count'] as int? ?? 0) + 1;
        }
      }
      return http.Response(
        json.encode({'message': 'Successfully joined event'}),
        201,
        headers: _jsonHeaders,
      );
    }

    final followMatch = RegExp(r'^/users/(\d+)/follow$').firstMatch(cleanPath);
    if (followMatch != null) {
      final targetId = int.parse(followMatch.group(1)!);
      if (!_mockFollowing.any((u) => u['id'] == targetId)) {
        // Reuse a known mock user (for example one found by search).
        _mockFollowing.add(
          _mockFollowers.firstWhere(
            (u) => u['id'] == targetId,
            orElse: () => {
              'id': targetId,
              'username': 'Student_$targetId',
              'email': 'student$targetId@epfl.ch',
              'role': 'student',
              'created_at': DateTime.now().toIso8601String(),
            },
          ),
        );
      }
      return http.Response(
        json.encode({'message': 'Followed user'}),
        201,
        headers: _jsonHeaders,
      );
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
        'retain_until': DateTime.now()
            .add(const Duration(days: 730))
            .toIso8601String(),
      };
      return http.Response(
        json.encode(_mockHealth),
        201,
        headers: _jsonHeaders,
      );
    }

    return http.Response(
      json.encode({'message': 'Created'}),
      201,
      headers: _jsonHeaders,
    );
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
      if (data.containsKey('username')) {
        _mockUser['username'] = data['username'];
      }
      if (data.containsKey('email')) {
        _mockUser['email'] = data['email'];
      }
      return http.Response(json.encode(_mockUser), 200, headers: _jsonHeaders);
    }

    if (cleanPath == '/users/me/preferences') {
      data.forEach((k, v) => _mockPreferences[k] = v);
      return http.Response(
        json.encode(_mockPreferences),
        200,
        headers: _jsonHeaders,
      );
    }

    if (cleanPath == '/health') {
      if (_mockHealth != null) {
        data.forEach((k, v) => _mockHealth![k] = v);
      }
      return http.Response(
        json.encode(_mockHealth),
        200,
        headers: _jsonHeaders,
      );
    }

    if (cleanPath == '/auth/password') {
      return http.Response(
        json.encode({'message': 'Password updated successfully'}),
        200,
        headers: _jsonHeaders,
      );
    }

    final singleActivityMatch = RegExp(
      r'^/activities/(\d+)$',
    ).firstMatch(cleanPath);
    if (singleActivityMatch != null) {
      final activityId = int.parse(singleActivityMatch.group(1)!);
      final idx = _mockActivities.indexWhere((a) => a['id'] == activityId);
      if (idx != -1) {
        final updated = Map<String, dynamic>.from(_mockActivities[idx]);
        data.forEach((k, v) => updated[k] = v);
        _mockActivities[idx] = updated;
        return http.Response(
          json.encode(_mockActivities[idx]),
          200,
          headers: _jsonHeaders,
        );
      }
    }

    return http.Response(
      json.encode({'message': 'Updated'}),
      200,
      headers: _jsonHeaders,
    );
  }

  /// Handles DELETE requests
  http.Response handleDelete(String path) {
    final uri = Uri.parse(path.startsWith('/') ? path : '/$path');
    final cleanPath = uri.path;

    if (cleanPath == '/users/me') {
      _mockActivities.clear();
      return http.Response(
        json.encode({'message': 'Account deleted successfully'}),
        200,
        headers: _jsonHeaders,
      );
    }

    if (cleanPath == '/health') {
      _mockHealth = null;
      return http.Response(
        json.encode({'message': 'Health data deleted successfully'}),
        200,
        headers: _jsonHeaders,
      );
    }

    final eventParticipantsMatch = RegExp(
      r'^/events/(\d+)/participants$',
    ).firstMatch(cleanPath);
    if (eventParticipantsMatch != null) {
      final eventId = int.parse(eventParticipantsMatch.group(1)!);
      final list = _mockEventParticipants[eventId];
      final currentId = _mockUser['id'];
      if (list != null) {
        list.removeWhere((u) => u['id'] == currentId);
        final ev = _mockEvents.firstWhere(
          (e) => e['id'] == eventId,
          orElse: () => {},
        );
        if (ev.isNotEmpty && (ev['participant_count'] as int? ?? 0) > 0) {
          ev['participant_count'] = (ev['participant_count'] as int) - 1;
        }
      }
      return http.Response(
        json.encode({'message': 'Left event'}),
        200,
        headers: _jsonHeaders,
      );
    }

    final followMatch = RegExp(r'^/users/(\d+)/follow$').firstMatch(cleanPath);
    if (followMatch != null) {
      final targetId = int.parse(followMatch.group(1)!);
      _mockFollowing.removeWhere((u) => u['id'] == targetId);
      return http.Response(
        json.encode({'message': 'Unfollowed user'}),
        200,
        headers: _jsonHeaders,
      );
    }

    final singleActivityMatch = RegExp(
      r'^/activities/(\d+)$',
    ).firstMatch(cleanPath);
    if (singleActivityMatch != null) {
      final activityId = int.parse(singleActivityMatch.group(1)!);
      _mockActivities.removeWhere((a) => a['id'] == activityId);
      return http.Response(
        json.encode({'message': 'Activity deleted'}),
        200,
        headers: _jsonHeaders,
      );
    }

    return http.Response(
      json.encode({'message': 'Deleted successfully'}),
      200,
      headers: _jsonHeaders,
    );
  }

  Future<http.Response> handleUpload(
    String path, {
    required List<int> bytes,
    required String filename,
    String field = 'file',
    Map<String, String>? fields,
  }) async {
    final cleanPath = path.split('?').first;

    if (cleanPath == '/users/me/photo') {
      return http.Response(
        json.encode({
          'photo_url':
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
        }),
        200,
        headers: _jsonHeaders,
      );
    }

    if (cleanPath == '/activities/import-fit') {
      final meta = FitDecoder.parseMetadata(Uint8List.fromList(bytes));
      final newActivityId =
          (_mockActivities
              .map((a) => a['id'] as int)
              .fold(200, (max, id) => id > max ? id : max)) +
          1;
      final defaultTitle = switch (meta.sport) {
        'run' => 'Running',
        'cycle' => 'Cycling',
        'walk' => 'Walking',
        'hike' => 'Hiking',
        'swim' => 'Swimming',
        _ => 'Imported FIT activity',
      };
      final newActivity = <String, dynamic>{
        'id': newActivityId,
        'title': defaultTitle,
        'type': meta.sport,
        'user_id': _mockUser['id'],
        'is_public': false,
        'duration': meta.durationMinutes ?? 45.0,
        'distance_km': meta.distanceKm ?? 5.2,
        'has_fit': true,
        'created_at':
            meta.startTime?.toUtc().toIso8601String() ??
            DateTime.now().toUtc().toIso8601String(),
      };
      _mockActivities.insert(0, newActivity);
      _mockWaypoints[newActivityId] = meta.waypoints.length >= 2
          ? List<Map<String, dynamic>>.from(meta.waypoints)
          : List<Map<String, dynamic>>.from(_defaultMockWaypoints);
      return http.Response(
        json.encode(newActivity),
        201,
        headers: _jsonHeaders,
      );
    }

    final activityFitMatch = RegExp(
      r'^/activities/(\d+)/fit$',
    ).firstMatch(cleanPath);
    if (activityFitMatch != null) {
      final actId = int.parse(activityFitMatch.group(1)!);
      final meta = FitDecoder.parseMetadata(Uint8List.fromList(bytes));
      final waypointsToUse = meta.waypoints.length >= 2
          ? List<Map<String, dynamic>>.from(meta.waypoints)
          : List<Map<String, dynamic>>.from(_defaultMockWaypoints);
      _mockWaypoints[actId] = waypointsToUse;

      final idx = _mockActivities.indexWhere((a) => a['id'] == actId);
      if (idx != -1) {
        final current = Map<String, dynamic>.from(_mockActivities[idx]);
        current['has_fit'] = true;
        if (meta.sport != 'other') {
          current['type'] = meta.sport;
        }
        if (meta.durationMinutes != null && meta.durationMinutes! > 0) {
          current['duration'] = meta.durationMinutes;
        }
        if (meta.distanceKm != null && meta.distanceKm! > 0) {
          current['distance_km'] = meta.distanceKm;
        }
        _mockActivities[idx] = current;
        return http.Response(json.encode(current), 200, headers: _jsonHeaders);
      }
      return http.Response(
        json.encode({'message': 'Activity not found'}),
        404,
        headers: _jsonHeaders,
      );
    }

    final eventImportMatch = RegExp(
      r'^/events/(\d+)/import-fit$',
    ).firstMatch(cleanPath);
    if (eventImportMatch != null) {
      final eventId = int.parse(eventImportMatch.group(1)!);
      final meta = FitDecoder.parseMetadata(Uint8List.fromList(bytes));
      final waypointsToUse = meta.waypoints.length >= 2
          ? List<Map<String, dynamic>>.from(meta.waypoints)
          : List<Map<String, dynamic>>.from(_defaultMockWaypoints);
      _mockEventWaypoints[eventId] = waypointsToUse;

      final event = _mockEvents.firstWhere(
        (e) => e['id'] == eventId,
        orElse: () => {},
      );
      if (event.isNotEmpty) {
        final resolvedSport = meta.sport != 'other' ? meta.sport : 'run';
        event['sport'] = resolvedSport;
        if (meta.distanceKm != null && meta.distanceKm! > 0) {
          event['distance_m'] = meta.distanceKm! * 1000.0;
        }
        if (meta.durationMinutes != null && meta.durationMinutes! > 0) {
          event['duration_minutes'] = meta.durationMinutes;
        }
      }

      final participants = _mockEventParticipants[eventId] ?? [_mockUser];
      for (final p in participants) {
        final pId = p['id'] as int;
        final newActId =
            (_mockActivities
                .map((a) => a['id'] as int)
                .fold(200, (max, id) => id > max ? id : max)) +
            1;
        final newAct = <String, dynamic>{
          'id': newActId,
          'title': event['title'] ?? 'Event Outing',
          'type': meta.sport != 'other' ? meta.sport : 'run',
          'user_id': pId,
          'is_public': true,
          'has_fit': true,
          'is_from_event': true,
          'event_id': eventId,
          'duration': meta.durationMinutes ?? 45.0,
          'distance_km':
              meta.distanceKm ??
              (((event['distance_m'] as num?)?.toDouble() ?? 5000.0) / 1000.0),
          'created_at':
              event['start_time'] ?? DateTime.now().toUtc().toIso8601String(),
        };
        _mockActivities.insert(0, newAct);
        _mockWaypoints[newActId] = List<Map<String, dynamic>>.from(
          waypointsToUse,
        );
      }

      return http.Response(
        json.encode({
          'inserted': waypointsToUse.length,
          'waypoints': waypointsToUse,
          'distributed_participants': participants.length,
        }),
        201,
        headers: _jsonHeaders,
      );
    }

    return http.Response(
      json.encode({'message': 'Uploaded successfully'}),
      200,
      headers: _jsonHeaders,
    );
  }

  void clearEventWaypoints([int? eventId]) {
    if (eventId != null) {
      _mockEventWaypoints.remove(eventId);
      final ev = _mockEvents.firstWhere(
        (e) => e['id'] == eventId,
        orElse: () => {},
      );
      if (ev.isNotEmpty) {
        ev.remove('duration_minutes');
        ev.remove('sport');
        if (eventId == 104) ev['distance_m'] = 5000.0;
      }
    } else {
      _mockEventWaypoints.clear();
      for (final ev in _mockEvents) {
        ev.remove('duration_minutes');
        ev.remove('sport');
        if (ev['id'] == 104) ev['distance_m'] = 5000.0;
      }
    }
  }

  void resetMockActivities() {
    setMockUserProfile(userId: 1);
    _mockActivities
      ..clear()
      ..addAll(_buildInitialActivities());
    _mockWaypoints
      ..clear()
      ..addAll(_buildInitialWaypoints());
  }
}
