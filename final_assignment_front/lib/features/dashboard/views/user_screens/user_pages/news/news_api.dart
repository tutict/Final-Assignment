import 'dart:convert';
import 'dart:developer' as develop;
import 'package:http/http.dart' as http;
import 'article.dart';

class NewsApi {
  static const String apiKey = 'Your_API_Key';
  static const String baseUrl = 'https://api.apilayer.com/world_news/search-news';

  Future<List<Article>> fetchArticles(String query, {int page = 1}) async {
    develop.log("Fetching articles for query: $query, page: $page");

    final uri = Uri.parse('$baseUrl?text=$query&page=$page');
    final response = await http.get(uri, headers: {'apikey': apiKey});

    develop.log("Response Status Code: ${response.statusCode}");
    develop.log("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['data'] != null && data['data'].isNotEmpty) {
        return (data['data'] as List)
            .map((articleJson) => Article.fromJson(articleJson))
            .toList();
      } else {
        throw Exception('No articles found.');
      }
    } else {
      throw Exception('Failed to fetch articles: ${response.reasonPhrase}');
    }
  }
}
