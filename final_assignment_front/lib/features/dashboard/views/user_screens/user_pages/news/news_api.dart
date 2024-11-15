import 'dart:convert';
import 'dart:developer' as develop;

import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/news/article.dart';
import 'package:http/http.dart' as http;

class NewsApi {
  static const String apiKey = 'Av858p4f03IFUYmkubfWNun8K1mDK612';
  static const String baseUrl =
      'https://api.apilayer.com/world_news/extract-news';

  Future<List<Article>> fetchArticles(String targetUrl) async {
    develop.log("Received targetUrl in fetchArticles: $targetUrl");

    final uri = Uri.parse('$baseUrl?url=$targetUrl&analyze=交通');
    develop.log("Constructed URI: $uri");

    final response = await http.get(
      uri,
      headers: {'apikey': apiKey},
    );

    develop.log("Response Status Code: ${response.statusCode}");
    develop.log("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['articles'] != null && data['articles'].isNotEmpty) {
        return (data['articles'] as List)
            .map((articleJson) => Article.fromJson(articleJson))
            .toList();
      } else {
        develop.log("No articles found in the response data.");
        throw Exception('No articles found in the response');
      }
    } else {
      develop.log("Failed to load articles: ${response.reasonPhrase}");
      throw Exception('Failed to load articles: ${response.reasonPhrase}');
    }
  }
}
