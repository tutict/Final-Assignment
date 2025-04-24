part of '../manager_screens/manager_dashboard_screen.dart';

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.data,
  });

  final ProjectCardData data;

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();

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
                          activeIcon: EvaIcons.book,
                          icon: EvaIcons.bookOutline,
                          label: "日志查阅",
                          routeName: Routes.logManagement,
                        ),
                        SelectionButtonData(
                          activeIcon: EvaIcons.people,
                          icon: EvaIcons.peopleOutline,
                          label: "用户管理",
                          routeName: Routes.userManagementPage,
                        ),
                        SelectionButtonData(
                          activeIcon: EvaIcons.email,
                          icon: EvaIcons.emailOutline,
                          label: "消息",
                          routeName: Routes.progressManagement,
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
                        debugPrint("index : $index | label : ${value.label}");
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
                    child: PoliceCard(
                      backgroundColor: Colors.transparent,
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
