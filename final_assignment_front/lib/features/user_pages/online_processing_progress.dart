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
    _tabController =
        TabController(length: 2, vsync: this); // ��ʼ��TabController
  }

  @override
  void dispose() {
    _tabController.dispose(); // �ͷ�TabController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('�������'),
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
                  title: Text('��������������'),
                  trailing: Icon(Icons.arrow_forward_ios),
                );
              },
            ),
          ),
          // ��� TabBar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '������'),
              Tab(text: '�Ѱ��'),
              Tab(text: '��ȡ��'),
              Tab(text: 'ȫ��'),
            ],
          ),
          // ��� TabBarView
          SizedBox(
            height: 200, // ���� TabBarView �ĸ߶�
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
