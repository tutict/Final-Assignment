part of '../user_dashboard.dart';

class UserSidebar extends StatelessWidget {
  const UserSidebar({
    super.key,
    required this.data,
  });

  final ProjectCardData data;

  @override
  Widget build(BuildContext context) {
    final UserDashboardController controller =
        Get.find<UserDashboardController>();

    return Obx(() {
      final ThemeData currentTheme = controller.currentBodyTheme.value;
      final bool isLight = currentTheme.brightness == Brightness.light;
      final Color backgroundColor =
          isLight ? Colors.white : currentTheme.cardColor;
      final Color dividerColor = isLight ? Colors.grey[500]! : Colors.white24;
      final TextStyle defaultTextStyle =
          TextStyle(color: isLight ? Colors.black87 : Colors.white);
      final IconThemeData defaultIconTheme =
          IconThemeData(color: isLight ? Colors.black87 : Colors.white);

      return Container(
        color: backgroundColor,
        child: DefaultTextStyle(
          style: defaultTextStyle,
          child: IconTheme(
            data: defaultIconTheme,
            child: SingleChildScrollView(
              controller: ScrollController(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(kSpacing),
                    child: ProjectCard(data: data),
                  ),
                  Divider(thickness: 1, color: dividerColor),
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
                          label: "业务点",
                          routeName: Routes.map,
                        ),
                        SelectionButtonData(
                          activeIcon: EvaIcons.calendar,
                          icon: EvaIcons.calendarOutline,
                          label: "业务办理",
                          routeName: Routes.businessProgress,
                        ),
                        SelectionButtonData(
                          activeIcon: EvaIcons.email,
                          icon: EvaIcons.emailOutline,
                          label: "进度消息",
                          routeName: Routes.onlineProcessingProgress,
                        ),
                        SelectionButtonData(
                          activeIcon: EvaIcons.person,
                          icon: EvaIcons.personOutline,
                          label: "个人",
                          routeName: Routes.personalMain,
                        ),
                        SelectionButtonData(
                          activeIcon: EvaIcons.settings,
                          icon: EvaIcons.settingsOutline,
                          label: "设置",
                          routeName: Routes.userSetting,
                        ),
                      ],
                      onSelected: (index, value) {
                        developer.log(
                            "index: $index | label: ${value.label} | route: ${value.routeName}");
                        if (value.routeName == "homePage") {
                          controller.exitSidebarContent();
                        } else {
                          controller.navigateToPage(value.routeName);
                        }
                      },
                    ),
                  ),
                  Divider(thickness: 1, color: dividerColor),
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
