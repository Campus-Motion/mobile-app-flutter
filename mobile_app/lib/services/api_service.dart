import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'mock_data_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = 'https://api.campusmotion.ch';
  static const String _tokenStorageKey = 'access_token';

  /// Global developer bypass / mock mode switch.
  /// Can be activated via --dart-define=MOCK_API=true or at runtime.
  static bool mockMode = const bool.fromEnvironment(
    'MOCK_API',
    defaultValue: false,
  );

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _token;

  String? get token => _token;

  Future<void> setToken(String? token) async {
    _token = token;
    try {
      if (token != null) {
        await _secureStorage.write(key: _tokenStorageKey, value: token);
      } else {
        await _secureStorage.delete(key: _tokenStorageKey);
      }
    } catch (_) {
      // Ignore secure storage platform errors when unavailable
    }
  }

  Future<void> clearToken() async {
    _token = null;
    try {
      await _secureStorage.delete(key: _tokenStorageKey);
    } catch (_) {
      // Ignore secure storage platform errors when unavailable
    }
  }

  Future<String?> loadStoredToken() async {
    try {
      _token = await _secureStorage.read(key: _tokenStorageKey);
    } catch (_) {
      _token = null;
    }
    return _token;
  }

  void enableMockMode() {
    mockMode = true;
  }

  void disableMockMode() {
    mockMode = false;
  }

  bool get isAuthenticated => _token != null;

  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  String _buildUrl(String path) {
    // Ensure path starts with a slash
    final formattedPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$formattedPath';
  }

  Future<http.Response> get(String path) async {
    final headers = _getHeaders();
    if (mockMode) {
      return MockDataService().handleGet(path, headers: headers);
    }
    try {
      final uri = Uri.parse(_buildUrl(path));
      final response = await http.get(uri, headers: headers);
      if (response.statusCode >= 500 && kDebugMode) {
        debugPrint(
          '[ApiService] Server returned ${response.statusCode} on $path. Falling back to developer mock data.',
        );
        return MockDataService().handleGet(path, headers: headers);
      }
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ApiService] Request failed on $path ($e). Falling back to developer mock data.',
        );
        return MockDataService().handleGet(path, headers: headers);
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
      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: bodyStr,
      );
      if (response.statusCode >= 500 && kDebugMode) {
        debugPrint(
          '[ApiService] Server returned ${response.statusCode} on $path. Falling back to developer mock data.',
        );
        return MockDataService().handlePost(path, body);
      }
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ApiService] Request failed on $path ($e). Falling back to developer mock data.',
        );
        return MockDataService().handlePost(path, body);
      }
      rethrow;
    }
  }

  /// Multipart writes never silently fall back to demo data.
  Future<http.Response> uploadFile(
    String path, {
    required List<int> bytes,
    required String filename,
    required String field,
  }) async {
    if (mockMode) {
      return MockDataService().handleUpload(path);
    }
    final request = http.MultipartRequest('POST', Uri.parse(_buildUrl(path)));
    request.headers.addAll(_getHeaders()..remove('Content-Type'));
    request.files.add(
      http.MultipartFile.fromBytes(field, bytes, filename: filename),
    );
    final streamed = await request.send().timeout(const Duration(seconds: 45));
    return http.Response.fromStream(
      streamed,
    ).timeout(const Duration(seconds: 45));
  }

  Future<http.Response> put(String path, dynamic body) async {
    if (mockMode) {
      return MockDataService().handlePut(path, body);
    }
    try {
      final uri = Uri.parse(_buildUrl(path));
      final bodyStr = body != null ? json.encode(body) : null;
      final response = await http.put(
        uri,
        headers: _getHeaders(),
        body: bodyStr,
      );
      if (response.statusCode >= 500 && kDebugMode) {
        debugPrint(
          '[ApiService] Server returned ${response.statusCode} on $path. Falling back to developer mock data.',
        );
        return MockDataService().handlePut(path, body);
      }
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ApiService] Request failed on $path ($e). Falling back to developer mock data.',
        );
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
        debugPrint(
          '[ApiService] Server returned ${response.statusCode} on $path. Falling back to developer mock data.',
        );
        return MockDataService().handleDelete(path);
      }
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ApiService] Request failed on $path ($e). Falling back to developer mock data.',
        );
        return MockDataService().handleDelete(path);
      }
      rethrow;
    }
  }
}
