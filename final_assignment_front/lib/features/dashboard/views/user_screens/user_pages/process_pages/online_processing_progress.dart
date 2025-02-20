import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    _tabController =
        TabController(length: 4, vsync: this); // Updated length to 4
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get current theme from context
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return CupertinoPageScaffold(
      backgroundColor: isLight
          ? CupertinoColors.white.withOpacity(0.9)
          : Colors.black.withOpacity(0.4),
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '网办进度',
          style: TextStyle(
            color: isLight ? CupertinoColors.black : CupertinoColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            controller.exitSidebarContent();
            Get.offNamed(Routes.userDashboard);
          },
          child: const Icon(CupertinoIcons.back),
        ),
        backgroundColor:
        isLight ? CupertinoColors.systemGrey5 : CupertinoColors.systemGrey,
        brightness:
        isLight ? Brightness.light : Brightness.dark, // Set brightness
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: 20,
                itemBuilder: (context, index) {
                  return CupertinoListTile(
                    title: Text('Item $index'),
                    trailing: const Icon(CupertinoIcons.forward),
                    onTap: () {
                      // Handle item tap
                    },
                  );
                },
              ),
            ),
            CupertinoSlidingSegmentedControl<int>(
              groupValue: _tabController.index,
              onValueChanged: (int? index) {
                if (index != null) {
                  setState(() {
                    _tabController.animateTo(index);
                  });
                }
              },
              children: const <int, Widget>{
                0: Text('受理中'),
                1: Text('处理中'),
                2: Text('已完成'),
                3: Text('已归档'),
              },
            ),
            SizedBox(
              height: 200,
              child: TabBarView(
                controller: _tabController, // Pass the TabController here
                children: const [
                  Center(child: Text('Tab 1 Content')),
                  Center(child: Text('Tab 2 Content')),
                  Center(child: Text('Tab 3 Content')),
                  Center(child: Text('Tab 4 Content')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const CupertinoListTile({
    required this.title,
    this.trailing,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: const BoxDecoration(
          color: CupertinoColors.white,
          border: Border(
            bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(child: title),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
