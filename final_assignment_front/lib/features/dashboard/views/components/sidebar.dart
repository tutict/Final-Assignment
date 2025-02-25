part of '../manager_screens/manager_dashboard_screen.dart';

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.data,
  });

  final ProjectCardData data; // 自定义数据类型

  @override
  Widget build(BuildContext context) {
    // 获取 DashboardController 实例
    final DashboardController controller = Get.find<DashboardController>();

    // 使用 Obx 监听主题变化
    return Obx(() {
      // 从控制器中获取当前主体主题数据
      final ThemeData currentTheme = controller.currentBodyTheme.value;
      // 判断当前是否为亮色模式
      final bool isLight = currentTheme.brightness == Brightness.light;
      // 亮色模式下背景为白色，暗色模式下使用主题中的 cardColor
      final Color backgroundColor =
          isLight ? Colors.white : currentTheme.cardColor;
      // 分割线颜色：亮色模式下使用浅灰色；暗色模式下使用透明度较低的白色
      final Color dividerColor = isLight ? Colors.grey[500]! : Colors.white24;
      // 定义默认文本和图标颜色：亮色模式下使用深色，暗色模式下使用白色
      final TextStyle defaultTextStyle =
          TextStyle(color: isLight ? Colors.black87 : Colors.white);
      final IconThemeData defaultIconTheme =
          IconThemeData(color: isLight ? Colors.black87 : Colors.white);

      return Container(
        color: backgroundColor,
        // 使用 DefaultTextStyle 与 IconTheme 统一设置文本和图标颜色
        child: DefaultTextStyle(
          style: defaultTextStyle,
          child: IconTheme(
            data: defaultIconTheme,
            child: SingleChildScrollView(
              controller: ScrollController(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 项目卡片区域
                  Padding(
                    padding: const EdgeInsets.all(kSpacing),
                    child: ProjectCard(data: data),
                  ),
                  Divider(thickness: 1, color: dividerColor),
                  // SelectionButton 区域
                  // 当处于暗色模式时，通过 Theme 复制当前主题并将 primaryColor 覆盖为蓝色，
                  // 使得按钮选中时其文本和图标显示为蓝色
                  Theme(
                    data: isLight
                        ? Theme.of(context)
                        : Theme.of(context).copyWith(primaryColor: Colors.blue),
                    child: SelectionButton(
                      data: [
                        SelectionButtonData(
                          activeIcon: EvaIcons.grid,
                          icon: EvaIcons.gridOutline,
                          label: "主页",
                          routeName: "homePage",
                        ),
                        SelectionButtonData(
                          activeIcon: EvaIcons.map,
                          icon: EvaIcons.archiveOutline,
                          label: "地图",
                          routeName: Routes.map,
                        ),
                        SelectionButtonData(
                          activeIcon: EvaIcons.calendar,
                          icon: EvaIcons.calendarOutline,
                          label: "业务处理",
                          routeName: Routes.managerBusinessProcessing,
                        ),
                        SelectionButtonData(
                          activeIcon: EvaIcons.email,
                          icon: EvaIcons.emailOutline,
                          label: "消息",
                          totalNotif: 20,
                          routeName: "messagePage",
                        ),
                        SelectionButtonData(
                          activeIcon: EvaIcons.person,
                          icon: EvaIcons.personOutline,
                          label: "个人信息",
                          routeName: Routes.managerPersonalPage,
                        ),
                        SelectionButtonData(
                          activeIcon: EvaIcons.settings,
                          icon: EvaIcons.settingsOutline,
                          label: "设置",
                          routeName: Routes.managerSetting,
                        ),
                      ],
                      onSelected: (index, value) {
                        log("index : $index | label : ${value.label}");
                        if (value.routeName == "homePage") {
                          // 如果点击的是“主页”，则退出侧边栏内容，显示默认 Dashboard 内容
                          controller.exitSidebarContent();
                        } else {
                          // 否则，导航到对应页面
                          controller.navigateToPage(value.routeName);
                        }
                      },
                    ),
                  ),
                  Divider(thickness: 1, color: dividerColor),
                  // PostCard 区域
                  Container(
                    padding: const EdgeInsets.all(kSpacing),
                    child: PostCard(
                      backgroundColor: isLight
                          ? Colors.grey[100]!.withAlpha((0.4 * 255).toInt())
                          : currentTheme.canvasColor
                              .withAlpha((0.4 * 255).toInt()),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
