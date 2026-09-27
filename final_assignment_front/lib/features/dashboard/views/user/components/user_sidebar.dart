part of '../user_dashboard.dart';

class UserSidebar extends StatelessWidget {
  const UserSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserDashboardController>();
    return Obx(() {
      final collapsed = !ResponsiveBuilder.isMobile(context) && controller.isSidebarCollapsed.value;
      return AppSidebar(
        groups: userShellGroups(),
        activePath: controller.activeNavRoute.value,
        collapsed: collapsed,
        brandMark: '办',
        brandTitle: '交通违法办事',
        onToggle: controller.toggleSidebarCollapsed,
        onSelect: (path) {
          if (path == 'homePage') {
            controller.exitSidebarContent();
          } else {
            controller.navigateToPage(path);
          }
        },
      );
    });
  }
}
