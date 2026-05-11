import 'package:final_assignment_front/features/dashboard/views/manager/pages/backup_and_restore.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/logs/login_log_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/logs/operation_log_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/logs/system_log_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/manager_personal_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/manager_setting.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/sidebar_management/log_management.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/sidebar_management/user_management_page.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/ai_chat.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/change_themes.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/map.dart';
import 'package:final_assignment_front/features/dashboard/bindings/chat_binding.dart';
import 'package:final_assignment_front/features/dashboard/bindings/log_binding.dart';
import 'package:final_assignment_front/features/dashboard/bindings/manager_dashboard_binding.dart';
import 'package:get/get.dart';

import 'app_routes.dart';

class AdminPages {
  static final routes = [
    GetPage(
      name: RoutePaths.aiChat,
      page: () => const AiChat(),
      binding: AiChatBinding(),
    ),
    GetPage(
      name: RoutePaths.map,
      page: () => const MapPage(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.backupAndRestore,
      page: () => const BackupAndRestore(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.managerPersonalPage,
      page: () => const ManagerPersonalPage(),
    ),
    GetPage(
      name: RoutePaths.managerSetting,
      page: () => const ManagerSetting(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.changeThemes,
      page: () => const ChangeThemes(),
    ),
    GetPage(
      name: RoutePaths.logManagement,
      page: () => const LogManagement(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.userManagementPage,
      page: () => const UserManagementPage(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.loginLogPage,
      page: () => const LoginLogPage(),
      binding: BindingsBuilder(() {
        DashboardBinding.registerDependencies();
        LogBinding.registerDependencies();
      }),
    ),
    GetPage(
      name: RoutePaths.operationLogPage,
      page: () => const OperationLogPage(),
      binding: BindingsBuilder(() {
        DashboardBinding.registerDependencies();
        LogBinding.registerDependencies();
      }),
    ),
    GetPage(
      name: RoutePaths.systemLogPage,
      page: () => const SystemLogPage(),
      binding: BindingsBuilder(() {
        DashboardBinding.registerDependencies();
        LogBinding.registerDependencies();
      }),
    ),
  ];
}
