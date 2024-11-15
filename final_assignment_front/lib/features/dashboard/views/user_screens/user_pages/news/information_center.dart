import 'dart:developer' as develop;

import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/news/article.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/news/news_api.dart';
import 'package:flutter/material.dart';

class InformationCenter extends StatelessWidget {
  const InformationCenter({super.key});

  @override
  Widget build(BuildContext context) {
    const targetUrl = 'https://news.sina.com.cn'; // Use the correct target URL
    develop.log("Target URL being passed to fetchArticles: $targetUrl"); // Log before passing

    return Scaffold(
      appBar: AppBar(
        title: const Text('最近的新闻'),
      ),
      body: FutureBuilder<List<Article>>(
        future: NewsApi().fetchArticles(targetUrl), // Correctly pass the URL
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No news available.'));
          } else {
            return _buildArticleList(snapshot.data!);
          }
        },
      ),
    );
  }

  Widget _buildArticleList(List<Article> articles) {
    return ListView.builder(
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return ListTile(
          leading: article.imageUrl.isNotEmpty
              ? Image.network(
            article.imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          )
              : const Icon(Icons.article, size: 50),
          title: Text(article.title),
          subtitle: Text(article.description),
        );
      },
    );
  }
}
