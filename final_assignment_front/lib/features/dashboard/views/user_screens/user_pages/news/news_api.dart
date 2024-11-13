import 'dart:convert';

import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/news/article.dart';
import 'package:http/http.dart' as http;

class NewsApi {
  static const String apiKey =
      'Av858p4f03IFUYmkubfWNun8K1mDK612'; // 替换为你的 API 密钥
  static const String baseUrl =
      'https://api.apilayer.com/world_news/extract-news';

  Future<List<Article>> fetchArticles(String targetUrl) async {
    final response = await http.get(
      Uri.parse('$baseUrl?url=$targetUrl&analyze=ok'),
      headers: {
        'apikey': apiKey,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Article> articles = (data['articles'] as List)
          .map((articleJson) => Article.fromJson(articleJson))
          .toList();
      return articles;
    } else {
      throw Exception('Failed to load articles');
    }
  }
}
