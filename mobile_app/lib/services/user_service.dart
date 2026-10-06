import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/user.dart';
import '../models/user_preferences.dart';
import '../models/health.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final ApiService _apiService = ApiService();

  Future<User> getMe() async {
    final response = await _apiService.get('/users/me');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return User.fromJson(data);
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  Future<User> getUser(int id) async {
    final response = await _apiService.get('/users/$id');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return User.fromJson(data);
    } else {
      throw Exception('Failed to load user');
    }
  }

  Future<User> updateMe({String? username, String? email}) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;

    final response = await _apiService.put('/users/me', body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return User.fromJson(data);
    } else {
      throw Exception('Failed to update profile');
    }
  }

  Future<void> deleteMe() async {
    final response = await _apiService.delete('/users/me');

    if (response.statusCode != 200) {
      throw Exception('Failed to request account deletion');
    }
  }

  Future<UserPreferences> getPreferences() async {
    final response = await _apiService.get('/users/me/preferences');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserPreferences.fromJson(data);
    } else {
      throw Exception('Failed to load preferences');
    }
  }

  Future<UserPreferences> updatePreferences(UserPreferences preferences) async {
    final response = await _apiService.put('/users/me/preferences', preferences.toJson());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserPreferences.fromJson(data);
    } else {
      throw Exception('Failed to update preferences: ${response.statusCode}');
    }
  }

  Future<HealthData?> getHealth() async {
    final response = await _apiService.get('/health');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return HealthData.fromJson(data);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load health data');
    }
  }

  Future<HealthData> createHealth(HealthData health) async {
    final response = await _apiService.post('/health', health.toJson());

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return HealthData.fromJson(data);
    } else {
      throw Exception('Failed to create health record: ${response.statusCode} - ${response.body}');
    }
  }

  Future<HealthData> updateHealth(HealthData health) async {
    final response = await _apiService.put('/health', health.toJson());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return HealthData.fromJson(data);
    } else {
      throw Exception('Failed to update health record: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> deleteHealth() async {
    final response = await _apiService.delete('/health');

    if (response.statusCode != 200) {
      throw Exception('Failed to request health data deletion');
    }
  }

  Future<String> uploadPhoto(List<int> bytes, String filename) async {
    final uri = Uri.parse('${ApiService.baseUrl}/users/me/photo');
    final request = http.MultipartRequest('POST', uri);
    
    final token = _apiService.token;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    final multipartFile = http.MultipartFile.fromBytes(
      'photo',
      bytes,
      filename: filename,
    );
    request.files.add(multipartFile);
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['photo_url'] as String;
    } else {
      throw Exception('Failed to upload photo');
    }
  }

  Future<List<User>> getFollowers(int id) async {
    final response = await _apiService.get('/users/$id/followers');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Backend returns either directly list or standard envelope. Let's handle both.
      final List<dynamic> list = (data is Map && data.containsKey('data')) 
          ? data['data'] as List 
          : (data as List? ?? []);
      return list.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load followers');
    }
  }

  Future<List<User>> getFollowing(int id) async {
    final response = await _apiService.get('/users/$id/following');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> list = (data is Map && data.containsKey('data')) 
          ? data['data'] as List 
          : (data as List? ?? []);
      return list.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load following');
    }
  }

  Future<void> followUser(int id) async {
    final response = await _apiService.post('/users/$id/follow', null);

    if (response.statusCode != 201) {
      try {
        final data = json.decode(response.body);
        final message = data['message'] as String?;
        throw Exception(message ?? 'Failed to follow user');
      } catch (_) {
        throw Exception('Failed to follow user');
      }
    }
  }

  Future<void> unfollowUser(int id) async {
    final response = await _apiService.delete('/users/$id/follow');

    if (response.statusCode != 200) {
      throw Exception('Failed to unfollow user');
    }
  }
}
