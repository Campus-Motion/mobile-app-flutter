import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = 'https://api.campusmotion.ch';
  String? _token;

  String? get token => _token;

  void setToken(String? token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
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
    final uri = Uri.parse(_buildUrl(path));
    return await http.get(uri, headers: _getHeaders());
  }

  Future<http.Response> post(String path, dynamic body) async {
    final uri = Uri.parse(_buildUrl(path));
    final bodyStr = body != null ? json.encode(body) : null;
    return await http.post(uri, headers: _getHeaders(), body: bodyStr);
  }

  Future<http.Response> put(String path, dynamic body) async {
    final uri = Uri.parse(_buildUrl(path));
    final bodyStr = body != null ? json.encode(body) : null;
    return await http.put(uri, headers: _getHeaders(), body: bodyStr);
  }

  Future<http.Response> delete(String path) async {
    final uri = Uri.parse(_buildUrl(path));
    return await http.delete(uri, headers: _getHeaders());
  }
}
