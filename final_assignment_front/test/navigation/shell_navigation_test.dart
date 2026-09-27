import 'package:final_assignment_front/config/navigation/shell_navigation.dart';
import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('driver navigation matches the task groups', () {
    final groups = userShellGroups();
    expect(groups.map((group) => group.label), ['首页', '办事', '查询', '我的']);
    expect(
      groups[1].items.map((item) => item.label),
      ['我的违法', '缴费', '申诉', '我的车辆'],
    );
    expect(groups[2].items.map((item) => item.label), ['消息', '地图']);
    expect(groups[2].items.last.path, RoutePaths.map);
    expect(
      groups[3].items.map((item) => item.label),
      ['个人资料', '咨询反馈', '设置'],
    );
    final labels = groups.expand((group) => group.items).map((item) => item.label);
    expect(labels, isNot(contains('退出登录')));
  });

  test('appeal reviewer only sees home, appeal, messages, profile and settings', () {
    final labels = managerShellGroups(superAdmin: false, appealReviewer: true)
        .expand((group) => group.items)
        .map((item) => item.label)
        .toList();
    expect(labels, ['首页', '申诉', '消息', '个人资料', '设置']);
  });

  test('admin sees business and oversight without the system group', () {
    final groups = managerShellGroups(superAdmin: false, appealReviewer: false);
    expect(groups.map((group) => group.id), isNot(contains('system')));
    expect(
      groups.firstWhere((group) => group.id == 'business').items.map((item) => item.label),
      ['违法行为', '罚款', '扣分', '申诉', '驾驶员', '车辆'],
    );
    expect(
      groups.firstWhere((group) => group.id == 'oversight').items.map((item) => item.label),
      ['消息', '缴费流水'],
    );
  });

  test('super admin keeps business pages and a collapsed system group', () {
    final groups = managerShellGroups(superAdmin: true, appealReviewer: false);
    expect(groups.any((group) => group.id == 'business'), isTrue);
    final system = groups.firstWhere((group) => group.id == 'system');
    expect(system.initiallyCollapsed, isTrue);
    expect(system.items.map((item) => item.label), [
      '操作日志',
      '登录日志',
      '系统日志',
      '请求记录',
      '账号',
      '角色',
      '权限',
      '违法类型',
      '系统参数',
      '备份恢复',
    ]);
  });

  test('legacy hubs, guides, themes and AI stay on the specified pages', () {
    expect(mapLegacyRoute(RoutePaths.trafficViolationScreen).home, isTrue);
    expect(mapLegacyRoute(RoutePaths.businessProgress).home, isTrue);
    expect(mapLegacyRoute(RoutePaths.managerBusinessProcessing).home, isTrue);
    expect(mapLegacyRoute(RoutePaths.offenseScreen).home, isTrue);

    final adminTheme = mapLegacyRoute(RoutePaths.changeThemes);
    expect(adminTheme.route, RoutePaths.managerSetting);
    expect(adminTheme.section, 'appearance');

    final userTheme = mapLegacyRoute(RoutePaths.userChangeThemes);
    expect(userTheme.route, RoutePaths.userSetting);
    expect(userTheme.section, 'appearance');
    expect(mapLegacyRoute(RoutePaths.managerSetting).section, isNull);
    expect(mapLegacyRoute(RoutePaths.userSetting).section, isNull);

    expect(mapLegacyRoute(RoutePaths.onlineProcessing).route, RoutePaths.onlineProcessingProgress);
    expect(mapLegacyRoute(RoutePaths.systemGovernance).route, RoutePaths.operationLogPage);
    expect(mapLegacyRoute(RoutePaths.logManagement).route, RoutePaths.operationLogPage);
    expect(mapLegacyRoute(RoutePaths.latestOffenseNewsPage).guide, 'news');
    expect(mapLegacyRoute(RoutePaths.finePaymentNoticePage).guide, 'payment');
    expect(mapLegacyRoute(RoutePaths.accidentQuickGuidePage).guide, 'quick');
    expect(mapLegacyRoute(RoutePaths.accidentProgressPage).guide, 'flow');
    expect(mapLegacyRoute(RoutePaths.accidentEvidencePage).guide, 'evidence');
    expect(mapLegacyRoute(RoutePaths.accidentVideoQuickPage).guide, 'video');

    final chat = mapLegacyRoute(RoutePaths.aiChat);
    expect(chat.openChat, isTrue);
    expect(chat.preservePage, isTrue);
    expect(chat.home, isFalse);
  });

  test('direct routes follow the same role boundaries as the navigation', () {
    expect(shellAllowsUserRoute(RoutePaths.map), isTrue);
    expect(shellAllowsUserRoute(RoutePaths.userManagementPage), isFalse);
    expect(shellAllowsManagerRoute(RoutePaths.offenseList, 'APPEAL_REVIEWER'), isFalse);
    expect(shellAllowsManagerRoute(RoutePaths.appealManagement, 'APPEAL_REVIEWER'), isTrue);
    expect(shellAllowsManagerRoute(RoutePaths.backupAndRestore, 'ADMIN'), isFalse);
    expect(shellAllowsManagerRoute(RoutePaths.paymentRecord, 'ADMIN'), isTrue);
    expect(shellAllowsManagerRoute(RoutePaths.offenseType, 'SUPER_ADMIN'), isTrue);
  });
}
