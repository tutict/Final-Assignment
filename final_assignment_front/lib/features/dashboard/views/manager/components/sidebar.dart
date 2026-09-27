part of '../manager_dashboard_screen.dart';

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ManagerDashboardController>();
    return Obx(() {
      final collapsed = !ResponsiveBuilder.isMobile(context) && controller.isSidebarCollapsed.value;
      return AppSidebar(
        groups: managerShellGroups(
          superAdmin: controller.isSuperAdmin,
          appealReviewer: controller.isAppealReviewer,
        ),
        activePath: controller.activeNavRoute.value,
        collapsed: collapsed,
        brandMark: '管',
        brandTitle: '交通违法管理',
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
