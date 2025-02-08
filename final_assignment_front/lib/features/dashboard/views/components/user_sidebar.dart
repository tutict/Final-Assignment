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

    // 根据当前亮度判断使用不同的颜色
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    // 在亮色模式下使用白色背景，否则使用 theme.cardColor（通常较暗）
    final Color backgroundColor =
        isLight ? Colors.white : Theme.of(context).cardColor;
    // 分割线颜色在亮色模式下用较浅的灰色，在暗色模式下用较深的颜色
    final Color dividerColor = isLight ? Colors.grey[300]! : Colors.white24;

    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        controller: ScrollController(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 让子项尽可能填满宽度
          children: [
            Padding(
              padding: const EdgeInsets.all(kSpacing),
              child: ProjectCard(data: data),
            ),
            Divider(thickness: 1, color: dividerColor),
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
                log("index : $index | label : ${value.label}");
                controller.navigateToPage(value.routeName);
              },
            ),
            Divider(thickness: 1, color: dividerColor),
            // 对 PostCard 在亮色模式下使用较浅的背景
            PostCard(
              backgroundColor: isLight
                  ? Colors.grey[100]!.withAlpha((0.4 * 255).toInt())
                  : Theme.of(context)
                      .canvasColor
                      .withAlpha((0.4 * 255).toInt()),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
