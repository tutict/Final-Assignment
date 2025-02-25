import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';

/// 进度消息数据模型
class ProgressItem {
  final int id;
  final String title;
  final String status;
  final String submitTime;
  final String? details;

  ProgressItem({
    required this.id,
    required this.title,
    required this.status,
    required this.submitTime,
    this.details,
  });

  factory ProgressItem.fromJson(Map<String, dynamic> json) {
    return ProgressItem(
      id: json['id'] as int,
      title: json['title'] as String,
      status: json['status'] as String,
      submitTime: json['submitTime'] as String,
      details: json['details'] as String?,
    );
  }
}

/// 模拟的进度消息 API
/// TODO: 模拟数据，实际应用中需要替换为实际数据
class ProgressApi {
  Future<List<ProgressItem>> fetchProgress(String status) async {
    await Future.delayed(const Duration(seconds: 1)); // 模拟网络延迟
    List<Map<String, dynamic>> mockData = [
      {
        'id': 1,
        'title': '罚款缴纳',
        'status': '受理中',
        'submitTime': '2023-10-01',
        'details': '罚款 \$100'
      },
      {
        'id': 2,
        'title': '申诉处理',
        'status': '处理中',
        'submitTime': '2023-10-02',
        'details': '超速申诉'
      },
      {
        'id': 3,
        'title': '车辆登记',
        'status': '已完成',
        'submitTime': '2023-10-03',
        'details': '新车登记'
      },
      {
        'id': 4,
        'title': '事故处理',
        'status': '已归档',
        'submitTime': '2023-10-04',
        'details': '轻微碰撞'
      },
    ];
    return mockData
        .where((data) => data['status'] == status)
        .map((json) => ProgressItem.fromJson(json))
        .toList();
  }
}

class OnlineProcessingProgress extends StatefulWidget {
  const OnlineProcessingProgress({super.key});

  @override
  OnlineProcessingProgressState createState() =>
      OnlineProcessingProgressState();
}

class OnlineProcessingProgressState extends State<OnlineProcessingProgress>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  final ProgressApi progressApi = ProgressApi();
  late List<Future<List<ProgressItem>>> _progressFutures;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _progressFutures = [
      progressApi.fetchProgress('受理中'),
      progressApi.fetchProgress('处理中'),
      progressApi.fetchProgress('已完成'),
      progressApi.fetchProgress('已归档'),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goToDetailPage(ProgressItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgressDetailPage(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Theme(
        data: controller.currentBodyTheme.value,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('进度消息'),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: '受理中'),
                Tab(text: '处理中'),
                Tab(text: '已完成'),
                Tab(text: '已归档'),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProgressList(context, '受理中', _progressFutures[0]),
                _buildProgressList(context, '处理中', _progressFutures[1]),
                _buildProgressList(context, '已完成', _progressFutures[2]),
                _buildProgressList(context, '已归档', _progressFutures[3]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressList(
      BuildContext context, String status, Future<List<ProgressItem>> future) {
    return FutureBuilder<List<ProgressItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary));
        } else if (snapshot.hasError) {
          return Center(
              child: Text('加载失败: ${snapshot.error}',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child: Text('暂无记录',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)));
        } else {
          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(item.status),
                  child: Text(
                    item.title[0],
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  item.title,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
                subtitle: Text(
                  '提交时间: ${item.submitTime}',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7)),
                ),
                trailing:
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: () => _goToDetailPage(item),
              );
            },
          );
        }
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '受理中':
        return Colors.orange;
      case '处理中':
        return Colors.blue;
      case '已完成':
        return Colors.green;
      case '已归档':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class ProgressDetailPage extends StatelessWidget {
  final ProgressItem item;

  const ProgressDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('业务详情'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: Text('业务ID',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              subtitle: Text(item.id.toString(),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
            ListTile(
              title: Text('业务类型',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              subtitle: Text(item.title,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
            ListTile(
              title: Text('状态',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              subtitle: Text(item.status,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
            ListTile(
              title: Text('提交时间',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              subtitle: Text(item.submitTime,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
            ListTile(
              title: Text('详情',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              subtitle: Text(item.details ?? '无',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
          ],
        ),
      ),
    );
  }
}
