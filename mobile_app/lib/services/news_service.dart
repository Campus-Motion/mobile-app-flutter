import 'dart:convert';
import 'api_service.dart';
import '../models/news_item.dart';

class NewsService {
  final ApiService _apiService = ApiService();

  Future<List<NewsItem>> fetchLatestNews() async {
    final response = await _apiService.get('/news');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> newsList = data['data'];
      
      return newsList.map((json) => NewsItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load news');
    }
  }
}
