part of '../user_screens/user_dashboard.dart';

class UserSidebar extends StatelessWidget {
  const UserSidebar({
    super.key,
    required this.data,
  });

  final ProjectCardData data;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserDashboardController>();

    return Container(
      color: Theme.of(context).cardColor,
      child: SingleChildScrollView(
        controller: ScrollController(),
        child: Column(
          children: [
            ProjectCard(data: data),
            const Divider(thickness: 1),
            SelectionButton(
              data: [
                SelectionButtonData(
                  activeIcon: EvaIcons.grid,
                  icon: EvaIcons.gridOutline,
                  label: "更多",
                  routeName: "morePage",
                ),
                SelectionButtonData(
                  activeIcon: EvaIcons.trendingUp,
                  icon: EvaIcons.trendingUpOutline,
                  label: "网办进度",
                  routeName: "/onlineProcessingProgress",
                ),
                SelectionButtonData(
                  activeIcon: EvaIcons.globe,
                  icon: EvaIcons.globe2Outline,
                  label: "网办大厅",
                  routeName: AppPages.onlineProcessingProgress,
                ),
                SelectionButtonData(
                  activeIcon: EvaIcons.pin,
                  icon: EvaIcons.pinOutline,
                  label: "线下网点",
                  routeName: "offlinePointPage",
                ),
                SelectionButtonData(
                  activeIcon: EvaIcons.person,
                  icon: EvaIcons.personOutline,
                  label: "我的",
                  routeName: AppPages.personalMain,
                ),
                SelectionButtonData(
                  activeIcon: EvaIcons.settings,
                  icon: EvaIcons.settingsOutline,
                  label: "设置",
                  routeName: AppPages.setting,
                ),
              ],
              onSelected: (index, value) {
                log("index : \$index | label : \${value.label}");
                controller.navigateToPage(value.routeName);
              },
            ),
            const Divider(thickness: 1),
            PostCard(
              backgroundColor: Theme.of(context).canvasColor.withAlpha((0.4 * 255).toInt()),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
