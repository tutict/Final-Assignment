import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/news/article.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/news/news_api.dart';
import 'package:flutter/material.dart';

class InformationCenter extends StatelessWidget {
  const InformationCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('最近的新闻'),
      ),
      body: FutureBuilder<List<Article>>(
        future: NewsApi().fetchArticles('https://news.sina.com.cn/'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error: \${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No news available.'));
          } else {
            final articles = snapshot.data!;
            return ListView.builder(
              itemCount: articles.length,
              itemBuilder: (context, index) {
                final article = articles[index];
                return ListTile(
                  leading: article.imageUrl.isNotEmpty
                      ? Image.network(article.imageUrl,
                          width: 50, height: 50, fit: BoxFit.cover)
                      : null,
                  title: Text(article.title),
                  subtitle: Text(article.description),
                );
              },
            );
          }
        },
      ),
    );
  }
}
