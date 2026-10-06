import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'user_service.dart';
import 'api_service.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  User? _currentUser;

  User? get currentUser => _currentUser;

  /// Activates the developer mock bypass and sets up a local demo session.
  Future<User> enterDemoMode() async {
    _apiService.enableMockMode();
    _apiService.setToken('mock-dev-jwt-token');
    final user = await UserService().getMe();
    _currentUser = user;
    return user;
  }

  Future<User?> getProfile() async {
    try {
      final user = await UserService().getMe();
      _currentUser = user;
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<User> login(String email, String password) async {
    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access_token'] as String;
        _apiService.setToken(token);
        
        // Fetch the current user profile
        final user = await UserService().getMe();
        _currentUser = user;
        return user;
      } else {
        if (kDebugMode && response.statusCode >= 500) {
          debugPrint('[AuthService] Server error on login (${response.statusCode}). Falling back to demo mode.');
          return enterDemoMode();
        }
        final message = _parseErrorMessage(response);
        throw Exception(message ?? 'Invalid email or password');
      }
    } catch (e) {
      if (kDebugMode && !ApiService.mockMode) {
        debugPrint('[AuthService] Login network failure ($e). Falling back to developer demo bypass.');
        return enterDemoMode();
      }
      rethrow;
    }
  }

  Future<void> register(String username, String email, String password) async {
    final response = await _apiService.post('/auth/register', {
      'username': username,
      'email': email,
      'password': password,
    });

    if (response.statusCode == 201) {
      return;
    } else {
      final message = _parseErrorMessage(response);
      throw Exception(message ?? 'Registration failed');
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final response = await _apiService.put('/auth/password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });

    if (response.statusCode == 200) {
      return;
    } else {
      final message = _parseErrorMessage(response);
      throw Exception(message ?? 'Failed to modify password');
    }
  }

  Future<void> logout() async {
    try {
      if (_apiService.isAuthenticated) {
        await _apiService.post('/auth/logout', null);
      }
    } catch (_) {
      // Ignore logout backend failures, proceed to local logout
    } finally {
      _apiService.clearToken();
      _currentUser = null;
    }
  }

  String? _parseErrorMessage(dynamic response) {
    try {
      final data = json.decode(response.body);
      return data['message'] as String?;
    } catch (_) {
      return null;
    }
  }
}
