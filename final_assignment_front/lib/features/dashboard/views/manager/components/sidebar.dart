part of '../manager_dashboard_screen.dart';

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    final ManagerDashboardController controller =
        Get.find<ManagerDashboardController>();

    return Obx(() {
      final ThemeData currentTheme = controller.currentBodyTheme.value;
      final scheme = currentTheme.colorScheme;
      final Color backgroundColor = scheme.surface.withValues(alpha: 0.98);
      final Color dividerColor = scheme.outlineVariant.withValues(alpha: 0.55);
      final TextStyle defaultTextStyle = TextStyle(color: scheme.onSurface);
      final IconThemeData defaultIconTheme =
          IconThemeData(color: scheme.onSurface);

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
                  const SizedBox(height: kSpacing),
                  Theme(
                    data: currentTheme.copyWith(primaryColor: scheme.primary),
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
