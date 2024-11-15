import 'dart:developer' as develop;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/news/article.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/news/news_api.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ValueNotifier<bool> isLightTheme = ValueNotifier<bool>(true);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightTheme,
      builder: (context, isLight, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '交通新闻',
          theme: ThemeData(
            fontFamily: GoogleFonts.poppins().fontFamily,
            brightness: isLight ? Brightness.light : Brightness.dark,
          ),
          scaffoldMessengerKey: GlobalScaffoldMessenger.scaffoldMessengerKey,
          home: NewsDetailScreen(isLightTheme: isLightTheme),
        );
      },
    );
  }
}

// Global key to manage ScaffoldMessenger
class GlobalScaffoldMessenger {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
}

class NewsDetailScreen extends StatefulWidget {
  final ValueNotifier<bool> isLightTheme;

  const NewsDetailScreen({super.key, required this.isLightTheme});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController controller = ScrollController();
  String searchKeyword = '';
  bool isLoading = false;
  List<Article> news = [];

  @override
  void initState() {
    super.initState();
    controller.addListener(_scrollListener);
    getNews();
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = widget.isLightTheme.value;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: TextFormField(
          decoration: const InputDecoration(hintText: '搜索新闻'),
          onFieldSubmitted: (val) => getNews(searchKey: val),
        ),
        actions: [
          IconButton(
            onPressed: () => getNews(reload: true),
            icon: const Icon(Icons.refresh),
          ),
          Switch(
            value: isLightTheme,
            onChanged: (value) => widget.isLightTheme.value = value,
            activeTrackColor: isLightTheme
                ? Colors.grey[300]
                : Colors.grey[400], // Track border
            inactiveTrackColor: isLightTheme
                ? Colors.black12
                : Colors.black54, // Inactive track
            activeColor: isLightTheme
                ? Colors.black54
                : Colors.orangeAccent, // Active thumb
            inactiveThumbColor:
                isLightTheme ? Colors.white : Colors.white70, // Inactive thumb
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : news.isEmpty
              ? const Center(child: Text('没有新闻'))
              : ListView.builder(
                  controller: controller,
                  itemCount: news.length,
                  itemBuilder: (context, index) {
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
                                  placeholder: (context, url) => Container(
                                    height: 200,
                                    color: Colors.grey[300],
                                  ),
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
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> getNews({String? searchKey, bool reload = false}) async {
    if (reload) {
      setState(() {
        news.clear();
        isLoading = true;
      });
    } else {
      setState(() => isLoading = true);
    }

    try {
      // Use https://news.sina.com.cn as the default URL instead of 'general'
      final url =
          searchKey?.isEmpty ?? true ? 'https://news.sina.com.cn' : searchKey!;
      develop.log("Target URL being passed to fetchArticles: $url");

      final articles = await NewsApi().fetchArticles(url);
      if (!mounted) return;
      setState(() {
        news = articles;
      });
    } catch (e) {
      if (!mounted) return;
      GlobalScaffoldMessenger.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(e.toString().contains('Unauthorized')
              ? 'Error loading news: Unauthorized. Please check your API key.'
              : 'Error loading news: $e'),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _scrollListener() {
    if (controller.position.atEdge && controller.position.pixels != 0) {
      getNews(); // Load more news
    }
  }

  void _showArticleDetail(Article article) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(article.title),
        content: Text(article.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
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
