import 'package:flutter/material.dart';

class OnlineProcessingProgress extends StatefulWidget {
  const OnlineProcessingProgress({super.key});

  @override
  OnlineProcessingProgressState createState() =>
      OnlineProcessingProgressState();
}

class OnlineProcessingProgressState extends State<OnlineProcessingProgress>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 初始化TabController
  }

  @override
  void dispose() {
    _tabController.dispose(); // 释放TabController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('网办进度'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) {
                return const ListTile(
                  title: Text('以下数据来自于'),
                  trailing: Icon(Icons.arrow_forward_ios),
                );
              },
            ),
          ),
          // 添加 TabBar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '受理中'),
              Tab(text: '已办结'),
              Tab(text: '已取消'),
              Tab(text: '全部'),
            ],
          ),
          // 添加 TabBarView
          SizedBox(
            height: 200, // 设置 TabBarView 的高度
            child: TabBarView(
              controller: _tabController,
              children: const [
                Center(child: Text('Tab 1 Content')),
                Center(child: Text('Tab 2 Content')),
                Center(child: Text('Tab 2 Content')),
                Center(child: Text('Tab 2 Content')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
