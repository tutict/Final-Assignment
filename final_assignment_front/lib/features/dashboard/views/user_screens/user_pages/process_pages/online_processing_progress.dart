import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';

class OnlineProcessingProgress extends StatefulWidget {
  const OnlineProcessingProgress({super.key});

  @override
  OnlineProcessingProgressState createState() => OnlineProcessingProgressState();
}

class OnlineProcessingProgressState extends State<OnlineProcessingProgress> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserDashboardController controller = Get.find<UserDashboardController>();

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
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return CupertinoPageScaffold(
      backgroundColor: isLight ? CupertinoColors.extraLightBackgroundGray : CupertinoColors.darkBackgroundGray,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          '网办进度',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            Get.back(); // 与之前的返回逻辑保持一致
          },
          child: Icon(
            CupertinoIcons.back,
            color: isLight ? CupertinoColors.black : CupertinoColors.white,
          ),
        ),
        backgroundColor: isLight ? CupertinoColors.lightBackgroundGray : CupertinoColors.black.withOpacity(0.8),
        brightness: isLight ? Brightness.light : Brightness.dark,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : CupertinoColors.darkBackgroundGray.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: isLight ? Colors.grey.withOpacity(0.2) : Colors.black.withOpacity(0.3),
                    blurRadius: 8.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _tabController.index,
                onValueChanged: (int? index) {
                  if (index != null) {
                    setState(() {
                      _tabController.animateTo(index);
                    });
                  }
                },
                backgroundColor: isLight ? CupertinoColors.lightBackgroundGray : CupertinoColors.systemGrey6,
                thumbColor: isLight ? Colors.white : CupertinoColors.systemGrey4,
                padding: const EdgeInsets.all(8.0),
                children: const <int, Widget>{
                  0: Text('受理中'),
                  1: Text('处理中'),
                  2: Text('已完成'),
                  3: Text('已归档'),
                },
              ),
            ),
            Expanded(
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
          ],
        ),
      ),
    );
  }

  Widget _buildProgressList(BuildContext context, String status) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      itemCount: 2, // 示例数量
      itemBuilder: (context, index) {
        return CupertinoListTile(
          title: Text('$status Item $index'),
          trailing: Icon(
            CupertinoIcons.forward,
            color: isLight ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
          ),
          backgroundColor: isLight ? Colors.white : CupertinoColors.darkBackgroundGray.withOpacity(0.9),
          onTap: () {
            // Handle item tap
            debugPrint('$status Item $index tapped');
          },
        );
      },
    );
  }
}

class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color backgroundColor;

  const CupertinoListTile({
    required this.title,
    this.trailing,
    this.onTap,
    required this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0), // 添加垂直间距
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: isLight ? Colors.grey.withOpacity(0.2) : Colors.black.withOpacity(0.3),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: DefaultTextStyle(
                style: TextStyle(
                  color: isLight ? CupertinoColors.black : CupertinoColors.white,
                  fontSize: 16.0,
                ),
                child: title,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}