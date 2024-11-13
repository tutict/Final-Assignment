import 'package:cached_network_image/cached_network_image.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/news/article.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/news/news_api.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const NewsDetailScreen());

GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

void toggleDrawer() {
  if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
    _scaffoldKey.currentState?.openEndDrawer();
  } else {
    _scaffoldKey.currentState?.openDrawer();
  }
}

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key});

  @override
  State<StatefulWidget> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  String searchKeyword = '';
  bool isSwitched = false;
  bool isLoading = false;
  List<Article> news = [];
  late ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '交通新闻',
      theme: isSwitched
          ? ThemeData(
              fontFamily: GoogleFonts.poppins().fontFamily,
              brightness: Brightness.light,
            )
          : ThemeData(
              fontFamily: GoogleFonts.poppins().fontFamily,
              brightness: Brightness.dark,
            ),
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: TextFormField(
            decoration: const InputDecoration(hintText: '搜索新闻'),
            onFieldSubmitted: (String val) => getNews(searchKey: val),
          ),
          actions: [
            IconButton(
              onPressed: () => getNews(reload: true),
              icon: const Icon(Icons.refresh),
            ),
            Switch(
              value: isSwitched,
              onChanged: (bool value) => setState(() => isSwitched = value),
              activeTrackColor: Colors.white,
              activeColor: Colors.white,
            ),
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
      ),
    );
  }
  Future<void> getNews({String? searchKey, bool reload = false}) async {
    setState(() => isLoading = true);

    if (reload) {
      news = [];
    }

    try {
      final articles = await NewsApi().fetchArticles(searchKey ?? 'general');
      setState(() {
        news = articles;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        news = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading news: $e')),
      );
    }
  }

  @override
  void initState() {
    controller = (ScrollController()..addListener(_scrollListener));
    getNews();
    super.initState();
  }

  void _scrollListener() {
    if (controller.position.pixels == controller.position.maxScrollExtent &&
        !isLoading) {
      getNews();
    }
  }
}
