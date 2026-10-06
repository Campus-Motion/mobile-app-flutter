import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'mock_data_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = 'https://api.campusmotion.ch';
  
  /// Global developer bypass / mock mode switch.
  /// Can be activated via --dart-define=MOCK_API=true or at runtime.
  static bool mockMode = const bool.fromEnvironment('MOCK_API', defaultValue: false);

  String? _token;

  String? get token => _token;

  void setToken(String? token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  void enableMockMode() {
    mockMode = true;
  }

  void disableMockMode() {
    mockMode = false;
  }

  bool get isAuthenticated => _token != null;

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  String _buildUrl(String path) {
    // Ensure path starts with a slash
    final formattedPath = path.startsWith('/') ? path : '/$path';
    String url = '$baseUrl$formattedPath';
    
    // Bypass CORS policy during local web development if needed
    if (kIsWeb && kDebugMode) {
      url = 'https://corsproxy.io/?${Uri.encodeComponent(url)}';
    }
    return url;
  }

  Future<http.Response> get(String path) async {
    if (mockMode) {
      return MockDataService().handleGet(path);
    }
    try {
      final uri = Uri.parse(_buildUrl(path));
      final response = await http.get(uri, headers: _getHeaders());
      if (response.statusCode >= 500 && kDebugMode) {
        debugPrint('[ApiService] Server returned ${response.statusCode} on $path. Falling back to developer mock data.');
        return MockDataService().handleGet(path);
      }
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ApiService] Request failed on $path ($e). Falling back to developer mock data.');
        return MockDataService().handleGet(path);
      }
      rethrow;
    }
  }

  Future<http.Response> post(String path, dynamic body) async {
    if (mockMode) {
      return MockDataService().handlePost(path, body);
    }
    try {
      final uri = Uri.parse(_buildUrl(path));
      final bodyStr = body != null ? json.encode(body) : null;
      final response = await http.post(uri, headers: _getHeaders(), body: bodyStr);
      if (response.statusCode >= 500 && kDebugMode) {
        debugPrint('[ApiService] Server returned ${response.statusCode} on $path. Falling back to developer mock data.');
        return MockDataService().handlePost(path, body);
      }
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ApiService] Request failed on $path ($e). Falling back to developer mock data.');
        return MockDataService().handlePost(path, body);
      }
      rethrow;
    }
  }

  Future<http.Response> put(String path, dynamic body) async {
    if (mockMode) {
      return MockDataService().handlePut(path, body);
    }
    try {
      final uri = Uri.parse(_buildUrl(path));
      final bodyStr = body != null ? json.encode(body) : null;
      final response = await http.put(uri, headers: _getHeaders(), body: bodyStr);
      if (response.statusCode >= 500 && kDebugMode) {
        debugPrint('[ApiService] Server returned ${response.statusCode} on $path. Falling back to developer mock data.');
        return MockDataService().handlePut(path, body);
      }
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ApiService] Request failed on $path ($e). Falling back to developer mock data.');
        return MockDataService().handlePut(path, body);
      }
      rethrow;
    }
  }

  Future<http.Response> delete(String path) async {
    if (mockMode) {
      return MockDataService().handleDelete(path);
    }
    try {
      final uri = Uri.parse(_buildUrl(path));
      final response = await http.delete(uri, headers: _getHeaders());
      if (response.statusCode >= 500 && kDebugMode) {
        debugPrint('[ApiService] Server returned ${response.statusCode} on $path. Falling back to developer mock data.');
        return MockDataService().handleDelete(path);
      }
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ApiService] Request failed on $path ($e). Falling back to developer mock data.');
        return MockDataService().handleDelete(path);
      }
      rethrow;
    }
  }
}
