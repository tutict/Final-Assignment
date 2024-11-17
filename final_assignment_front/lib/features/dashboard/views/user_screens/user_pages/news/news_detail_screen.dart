import 'dart:developer' as develop;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'article.dart';
import 'article_detail.dart';
import 'news_api.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '交通新闻',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const NewsDetailScreen(),
    );
  }
}

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final ScrollController controller = ScrollController();
  bool isLoading = false;
  List<Article> news = [];
  String searchKeyword = '';
  int currentPage = 1;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    controller.addListener(_scrollListener);
    getNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          decoration: const InputDecoration(hintText: '搜索新闻'),
          onFieldSubmitted: (val) {
            searchKeyword = val;
            getNews(reload: true);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => getNews(reload: true),
          ),
        ],
      ),
      body: isLoading && news.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : news.isEmpty
          ? const Center(child: Text('没有新闻'))
          : ListView.builder(
        controller: controller,
        itemCount: news.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == news.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final article = news[index];
          return GestureDetector(
            onTap: () => _showArticleDetail(article),
            child: Card(
              margin: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: article.imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      article.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> getNews({bool reload = false}) async {
    if (reload) {
      setState(() {
        news.clear();
        currentPage = 1;
        hasMore = true;
      });
    }
    setState(() => isLoading = true);

    try {
      final articles = await NewsApi().fetchArticles(
        searchKeyword.isEmpty ? '交通事故' : searchKeyword,
        page: currentPage,
      );
      setState(() {
        news.addAll(articles);
        hasMore = articles.length == 10;
        if (hasMore) currentPage++;
      });
    } catch (e) {
      develop.log("Error fetching news: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _scrollListener() {
    if (controller.position.pixels == controller.position.maxScrollExtent &&
        hasMore) {
      getNews();
    }
  }

  void _showArticleDetail(Article article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailPage(article: article),
      ),
    );
  }

  @override
  void dispose() {
    controller.removeListener(_scrollListener);
    controller.dispose();
    super.dispose();
  }
}
