import 'package:final_assignment_front/features/dashboard/bindings/chat_binding.dart';
import 'package:final_assignment_front/features/dashboard/bindings/log_binding.dart';
import 'package:final_assignment_front/features/dashboard/bindings/manager_dashboard_binding.dart';
import 'package:get/get.dart';

import 'app_routes.dart';
import 'shell_redirect.dart';

class AdminPages {
  static final routes = [
    GetPage(
      name: RoutePaths.aiChat,
      page: () => const ShellRedirect(openChat: true),
      binding: AiChatBinding(),
    ),
    GetPage(
      name: RoutePaths.map,
      page: () => const ShellRedirect(page: RoutePaths.map),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.backupAndRestore,
      page: () => const ShellRedirect(page: RoutePaths.backupAndRestore, forceManager: true),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.managerPersonalPage,
      page: () => const ShellRedirect(page: RoutePaths.managerPersonalPage, forceManager: true),
    ),
    GetPage(
      name: RoutePaths.managerSetting,
      page: () => const ShellRedirect(page: RoutePaths.managerSetting, forceManager: true),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.changeThemes,
      page: () => const ShellRedirect(page: RoutePaths.managerSetting, forceManager: true, section: 'appearance'),
    ),
    GetPage(
      name: RoutePaths.logManagement,
      page: () => const ShellRedirect(page: RoutePaths.operationLogPage, forceManager: true),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.systemGovernance,
      page: () => const ShellRedirect(page: RoutePaths.operationLogPage, forceManager: true),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.ragManagement,
      page: () => const ShellRedirect(page: RoutePaths.ragManagement, forceManager: true),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.userManagementPage,
      page: () => const ShellRedirect(page: RoutePaths.userManagementPage, forceManager: true),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.loginLogPage,
      page: () => const ShellRedirect(page: RoutePaths.loginLogPage, forceManager: true),
      binding: BindingsBuilder(() {
        DashboardBinding.registerDependencies();
        LogBinding.registerDependencies();
      }),
    ),
    GetPage(
      name: RoutePaths.operationLogPage,
      page: () => const ShellRedirect(page: RoutePaths.operationLogPage, forceManager: true),
      binding: BindingsBuilder(() {
        DashboardBinding.registerDependencies();
        LogBinding.registerDependencies();
      }),
    ),
    GetPage(
      name: RoutePaths.systemLogPage,
      page: () => const ShellRedirect(page: RoutePaths.systemLogPage, forceManager: true),
      binding: BindingsBuilder(() {
        DashboardBinding.registerDependencies();
        LogBinding.registerDependencies();
      }),
    ),
  ];
}
