import 'package:flutter/material.dart';
import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/core/auth/role_utils.dart';

class ShellNavItem {
  const ShellNavItem({
    required this.label,
    required this.path,
    required this.icon,
  });

  final String label;
  final String path;
  final IconData icon;
}

class ShellNavGroup {
  const ShellNavGroup({
    required this.id,
    required this.label,
    required this.items,
    this.initiallyCollapsed = false,
  });

  final String id;
  final String label;
  final List<ShellNavItem> items;
  final bool initiallyCollapsed;
}

class LegacyRoute {
  const LegacyRoute({
    required this.route,
    this.guide,
    this.home = false,
    this.openChat = false,
    this.section,
    this.preservePage = false,
  });

  final String route;
  final String? guide;
  final bool home;
  final bool openChat;
  final String? section;
  final bool preservePage;
}

class ShellSession {
  static String? managerPage;
  static String? userPage;

  static void rememberManager(String? route) {
    if (route == null || route.isEmpty || route == RoutePaths.aiChat) return;
    managerPage = route;
  }

  static void rememberUser(String? route) {
    if (route == null || route.isEmpty || route == RoutePaths.aiChat) return;
    userPage = route;
  }
}

LegacyRoute mapLegacyRoute(String routeName) {
  switch (routeName) {
    case RoutePaths.businessProgress:
    case RoutePaths.managerBusinessProcessing:
    case RoutePaths.offenseScreen:
    case RoutePaths.trafficViolationScreen:
      return const LegacyRoute(route: 'homePage', home: true);
    case RoutePaths.latestOffenseNewsPage:
      return const LegacyRoute(route: 'homePage', home: true, guide: 'news');
    case RoutePaths.finePaymentNoticePage:
      return LegacyRoute(route: RoutePaths.fineInformation, guide: 'payment');
    case RoutePaths.accidentQuickGuidePage:
      return LegacyRoute(route: RoutePaths.userOffenseListPage, guide: 'quick');
    case RoutePaths.accidentProgressPage:
      return LegacyRoute(route: RoutePaths.userOffenseListPage, guide: 'flow');
    case RoutePaths.accidentEvidencePage:
      return LegacyRoute(route: RoutePaths.userOffenseListPage, guide: 'evidence');
    case RoutePaths.accidentVideoQuickPage:
      return LegacyRoute(route: RoutePaths.userOffenseListPage, guide: 'video');
    case RoutePaths.onlineProcessing:
      return LegacyRoute(route: RoutePaths.onlineProcessingProgress);
    case RoutePaths.changeThemes:
      return const LegacyRoute(route: RoutePaths.managerSetting, section: 'appearance');
    case RoutePaths.userChangeThemes:
      return const LegacyRoute(route: RoutePaths.userSetting, section: 'appearance');
    case RoutePaths.systemGovernance:
    case RoutePaths.logManagement:
      return LegacyRoute(route: RoutePaths.operationLogPage);
    case RoutePaths.aiChat:
      return const LegacyRoute(route: 'homePage', openChat: true, preservePage: true);
    default:
      return LegacyRoute(route: routeName);
  }
}

List<ShellNavGroup> userShellGroups() {
  return const [
    ShellNavGroup(
      id: 'home',
      label: '首页',
      items: [ShellNavItem(label: '首页', path: 'homePage', icon: Icons.home_outlined)],
    ),
    ShellNavGroup(
      id: 'tasks',
      label: '办事',
      items: [
        ShellNavItem(label: '我的违法', path: RoutePaths.userOffenseListPage, icon: Icons.report_gmailerrorred_outlined),
        ShellNavItem(label: '缴费', path: RoutePaths.fineInformation, icon: Icons.payments_outlined),
        ShellNavItem(label: '申诉', path: RoutePaths.userAppeal, icon: Icons.fact_check_outlined),
        ShellNavItem(label: '我的车辆', path: RoutePaths.vehicleManagement, icon: Icons.directions_car_outlined),
      ],
    ),
    ShellNavGroup(
      id: 'lookup',
      label: '查询',
      items: [
        ShellNavItem(label: '消息', path: RoutePaths.onlineProcessingProgress, icon: Icons.notifications_outlined),
        ShellNavItem(label: '地图', path: RoutePaths.map, icon: Icons.map_outlined),
      ],
    ),
    ShellNavGroup(
      id: 'account',
      label: '我的',
      items: [
        ShellNavItem(label: '个人资料', path: RoutePaths.personalMain, icon: Icons.person_outline),
        ShellNavItem(label: '咨询反馈', path: RoutePaths.consultation, icon: Icons.chat_outlined),
        ShellNavItem(label: '设置', path: RoutePaths.userSetting, icon: Icons.settings_outlined),
      ],
    ),
  ];
}

List<ShellNavGroup> managerShellGroups({
  required bool superAdmin,
  required bool appealReviewer,
}) {
  if (appealReviewer) {
    return const [
      ShellNavGroup(
        id: 'home',
        label: '首页',
        items: [ShellNavItem(label: '首页', path: 'homePage', icon: Icons.home_outlined)],
      ),
      ShellNavGroup(
        id: 'business',
        label: '业务',
        items: [ShellNavItem(label: '申诉', path: RoutePaths.appealManagement, icon: Icons.fact_check_outlined)],
      ),
      ShellNavGroup(
        id: 'oversight',
        label: '监管',
        items: [ShellNavItem(label: '消息', path: RoutePaths.progressManagement, icon: Icons.notifications_outlined)],
      ),
      ShellNavGroup(
        id: 'account',
        label: '我的',
        items: [
          ShellNavItem(label: '个人资料', path: RoutePaths.managerPersonalPage, icon: Icons.person_outline),
          ShellNavItem(label: '设置', path: RoutePaths.managerSetting, icon: Icons.settings_outlined),
        ],
      ),
    ];
  }

  return [
    const ShellNavGroup(
      id: 'home',
      label: '首页',
      items: [ShellNavItem(label: '首页', path: 'homePage', icon: Icons.home_outlined)],
    ),
    const ShellNavGroup(
      id: 'business',
      label: '业务',
      items: [
        ShellNavItem(label: '违法行为', path: RoutePaths.offenseList, icon: Icons.report_gmailerrorred_outlined),
        ShellNavItem(label: '罚款', path: RoutePaths.fineList, icon: Icons.payments_outlined),
        ShellNavItem(label: '扣分', path: RoutePaths.deductionManagement, icon: Icons.remove_circle_outline),
        ShellNavItem(label: '申诉', path: RoutePaths.appealManagement, icon: Icons.fact_check_outlined),
        ShellNavItem(label: '驾驶员', path: RoutePaths.driverList, icon: Icons.badge_outlined),
        ShellNavItem(label: '车辆', path: RoutePaths.vehicleList, icon: Icons.directions_car_outlined),
      ],
    ),
    const ShellNavGroup(
      id: 'oversight',
      label: '监管',
      items: [
        ShellNavItem(label: '消息', path: RoutePaths.progressManagement, icon: Icons.notifications_outlined),
        ShellNavItem(label: '缴费流水', path: RoutePaths.paymentRecord, icon: Icons.receipt_long_outlined),
      ],
    ),
    const ShellNavGroup(
      id: 'library',
      label: '资料',
      items: [ShellNavItem(label: 'RAG 资料', path: RoutePaths.ragManagement, icon: Icons.library_books_outlined)],
    ),
    if (superAdmin)
      const ShellNavGroup(
        id: 'system',
        label: '系统',
        initiallyCollapsed: true,
        items: [
          ShellNavItem(label: '操作日志', path: RoutePaths.operationLogPage, icon: Icons.manage_search_outlined),
          ShellNavItem(label: '登录日志', path: RoutePaths.loginLogPage, icon: Icons.login_outlined),
          ShellNavItem(label: '系统日志', path: RoutePaths.systemLogPage, icon: Icons.terminal_outlined),
          ShellNavItem(label: '请求记录', path: RoutePaths.requestHistory, icon: Icons.travel_explore_outlined),
          ShellNavItem(label: '账号', path: RoutePaths.userManagementPage, icon: Icons.manage_accounts_outlined),
          ShellNavItem(label: '角色', path: RoutePaths.roleManagement, icon: Icons.admin_panel_settings_outlined),
          ShellNavItem(label: '权限', path: RoutePaths.permissionManagement, icon: Icons.vpn_key_outlined),
          ShellNavItem(label: '违法类型', path: RoutePaths.offenseType, icon: Icons.category_outlined),
          ShellNavItem(label: '系统参数', path: RoutePaths.systemSettings, icon: Icons.tune_outlined),
          ShellNavItem(label: '备份恢复', path: RoutePaths.backupAndRestore, icon: Icons.backup_outlined),
        ],
      ),
    const ShellNavGroup(
      id: 'account',
      label: '我的',
      items: [
        ShellNavItem(label: '个人资料', path: RoutePaths.managerPersonalPage, icon: Icons.person_outline),
        ShellNavItem(label: '设置', path: RoutePaths.managerSetting, icon: Icons.settings_outlined),
      ],
    ),
  ];
}


const systemShellRoutes = <String>{
  RoutePaths.operationLogPage,
  RoutePaths.loginLogPage,
  RoutePaths.systemLogPage,
  RoutePaths.requestHistory,
  RoutePaths.userManagementPage,
  RoutePaths.roleManagement,
  RoutePaths.permissionManagement,
  RoutePaths.offenseType,
  RoutePaths.systemSettings,
  RoutePaths.backupAndRestore,
};

const appealShellRoutes = <String>{
  RoutePaths.appealManagement,
  RoutePaths.progressManagement,
  RoutePaths.managerPersonalPage,
  RoutePaths.managerSetting,
};

const userShellRoutes = <String>{
  RoutePaths.onlineProcessingProgress,
  RoutePaths.personalMain,
  RoutePaths.map,
  RoutePaths.userSetting,
  RoutePaths.consultation,
  RoutePaths.mainScan,
  RoutePaths.userOffenseListPage,
  RoutePaths.userAppeal,
  RoutePaths.fineInformation,
  RoutePaths.vehicleManagement,
};

bool shellAllowsUserRoute(String route) => userShellRoutes.contains(route);

bool shellAllowsManagerRoute(String route, Object? role) {
  final normalized = RoleUtils.preferredRole(role);
  if (normalized == 'APPEAL_REVIEWER') {
    return appealShellRoutes.contains(route);
  }
  if (systemShellRoutes.contains(route)) {
    return normalized == 'SUPER_ADMIN';
  }
  return normalized == 'ADMIN' || normalized == 'SUPER_ADMIN';
}


double shellPageMargin(double width) {
  if (width >= 1100) return 24;
  if (width >= 700) return 16;
  return 12;
}
