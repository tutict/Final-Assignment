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
                  Padding(
                    padding: const EdgeInsets.all(kSpacing),
                    child: ProjectCard(data: data),
                  ),
                  Divider(thickness: 1, color: dividerColor),
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
                          label: "业务办理",
                          routeName: Routes.businessProgress,
                        ),
                        SelectionButtonData(
                          activeIcon: EvaIcons.email,
                          icon: EvaIcons.emailOutline,
                          label: "进度消息",
                          routeName: Routes.onlineProcessingProgress,
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
                      backgroundColor: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.42),
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
