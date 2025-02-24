import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';

class OnlineProcessingProgress extends StatefulWidget {
  const OnlineProcessingProgress({super.key});

  @override
  OnlineProcessingProgressState createState() =>
      OnlineProcessingProgressState();
}

class OnlineProcessingProgressState extends State<OnlineProcessingProgress>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('网办进度'), // Material 风格标题
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '受理中'),
            Tab(text: '处理中'),
            Tab(text: '已完成'),
            Tab(text: '已归档'),
          ],
          labelColor: Colors.blue,
          // 选中标签颜色
          unselectedLabelColor: Colors.grey,
          // 未选中标签颜色
          indicatorColor: Colors.blue, // 下划线颜色
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 与 ManagerSetting.dart 一致的内边距
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildProgressList(context, '受理中'),
            _buildProgressList(context, '处理中'),
            _buildProgressList(context, '已完成'),
            _buildProgressList(context, '已归档'),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressList(BuildContext context, String status) {
    return ListView.builder(
      itemCount: 2, // 示例数量
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('$status Item $index'),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          // Material 风格右侧箭头
          onTap: () {
            // 处理列表项点击
            debugPrint('$status Item $index tapped');
          },
        );
      },
    );
  }
}
