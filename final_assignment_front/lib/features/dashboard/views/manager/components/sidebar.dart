part of '../manager_dashboard_screen.dart';

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.data,
  });

  final ProjectCardData data;

  @override
  Widget build(BuildContext context) {
    final ManagerDashboardController controller =
        Get.find<ManagerDashboardController>();

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
                          activeIcon: EvaIcons.calendar,
                          icon: EvaIcons.calendarOutline,
                          label: "业务处理",
                          routeName: Routes.managerBusinessProcessing,
                        ),
                        SelectionButtonData(
                          activeIcon: EvaIcons.email,
                          icon: EvaIcons.emailOutline,
                          label: "消息",
                          routeName: Routes.progressManagement,
                        ),
                      ],
                      onSelected: (index, value) {
                        AppLogger.debug(
                            "index : $index | label : ${value.label}");
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
