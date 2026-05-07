import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/news_item.dart';

class NewsService {
  static const String baseUrl = 'https://api.campusmotion.ch';

  Future<List<NewsItem>> fetchLatestNews() async {
    String url = '$baseUrl/news';
    
    // Bypass CORS policy during local web development
    if (kIsWeb && kDebugMode) {
      url = 'https://corsproxy.io/?$url';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> newsList = data['data'];
      
      return newsList.map((json) => NewsItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load news');
    }
  }
}
