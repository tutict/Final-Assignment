
import 'package:final_assignment_front/config/navigation/shell_navigation.dart';
import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/guide_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    GuideController.close();
    ShellSession.userPage = null;
    ShellSession.managerPage = null;
  });

  test('driver map stays on the map page and does not open admin lists', () {
    final controller = UserDashboardController();
    controller.navigateToPage(RoutePaths.map);
    expect(controller.activeNavRoute.value, RoutePaths.map);
    expect(controller.isShowingSidebarContent.value, isTrue);
    final labels = userShellGroups().expand((group) => group.items).map((item) => item.label);
    expect(labels, contains('地图'));
    expect(labels, isNot(contains('违法行为')));
  });

  test('payment scan opens inside the current shell', () {
    final controller = UserDashboardController();
    controller.navigateToPage(RoutePaths.fineInformation);
    controller.navigateToPage(RoutePaths.mainScan);
    expect(controller.activeNavRoute.value, RoutePaths.mainScan);
    expect(userShellGroups().expand((group) => group.items).map((item) => item.path), isNot(contains(RoutePaths.mainScan)));
  });

  test('AI toggle and the AI route stay on the current page', () {
    final controller = UserDashboardController();
    controller.navigateToPage(RoutePaths.fineInformation);
    controller.toggleChat();
    expect(controller.isChatExpanded.value, isTrue);
    expect(controller.activeNavRoute.value, RoutePaths.fineInformation);

    controller.navigateToPage(RoutePaths.aiChat);
    expect(controller.isChatExpanded.value, isTrue);
    expect(controller.activeNavRoute.value, RoutePaths.fineInformation);
    expect(ShellSession.userPage, RoutePaths.fineInformation);
  });

  test('guide and theme routes land on the host page', () {
    final controller = UserDashboardController();
    controller.navigateToPage(RoutePaths.latestOffenseNewsPage);
    expect(controller.activeNavRoute.value, 'homePage');
    expect(controller.isShowingSidebarContent.value, isFalse);
    expect(GuideController.guideId.value, 'news');

    controller.navigateToPage(RoutePaths.accidentEvidencePage);
    expect(controller.activeNavRoute.value, RoutePaths.userOffenseListPage);
    expect(GuideController.guideId.value, 'evidence');

    controller.navigateToPage(RoutePaths.finePaymentNoticePage);
    expect(controller.activeNavRoute.value, RoutePaths.fineInformation);
    expect(GuideController.guideId.value, 'payment');

    controller.navigateToPage(RoutePaths.userChangeThemes);
    expect(controller.activeNavRoute.value, RoutePaths.userSetting);
    expect(controller.focusAppearance.value, isTrue);
  });

  test('manager legacy hubs return home and theme opens appearance', () {
    final controller = ManagerDashboardController();
    controller.currentRole.value = 'ADMIN';
    controller.navigateToPage(RoutePaths.trafficViolationScreen);
    expect(controller.activeNavRoute.value, 'homePage');
    expect(controller.isShowingSidebarContent.value, isFalse);

    controller.navigateToPage(RoutePaths.changeThemes);
    expect(controller.activeNavRoute.value, RoutePaths.managerSetting);
    expect(controller.focusAppearance.value, isTrue);

    controller.currentRole.value = 'ADMIN';
    controller.navigateToPage(RoutePaths.offenseList);
    final page = controller.activeNavRoute.value;
    controller.toggleChat();
    controller.navigateToPage(RoutePaths.aiChat);
    expect(controller.activeNavRoute.value, page);
    expect(controller.isChatExpanded.value, isTrue);
  });

  test('logged-in role flags choose the same navigation the shell renders', () {
    final controller = ManagerDashboardController();

    controller.currentRole.value = 'ADMIN';
    expect(_labels(controller), [
      '首页',
      '违法行为',
      '罚款',
      '扣分',
      '申诉',
      '驾驶员',
      '车辆',
      '消息',
      '缴费流水',
      'RAG 资料',
      '个人资料',
      '设置',
    ]);

    controller.currentRole.value = 'SUPER_ADMIN';
    expect(_labels(controller), contains('违法行为'));
    expect(_labels(controller), contains('操作日志'));
    expect(_labels(controller), contains('备份恢复'));

    controller.currentRole.value = 'APPEAL_REVIEWER';
    expect(_labels(controller), ['首页', '申诉', '消息', '个人资料', '设置']);
  });

  test('appeal reviewer and admin cannot open pages outside their shell', () {
    final appeal = ManagerDashboardController();
    appeal.currentRole.value = 'APPEAL_REVIEWER';
    appeal.navigateToPage(RoutePaths.offenseList);
    appeal.navigateToPage(RoutePaths.userManagementPage);
    expect(appeal.activeNavRoute.value, 'homePage');
    expect(appeal.isShowingSidebarContent.value, isFalse);

    appeal.navigateToPage(RoutePaths.appealManagement);
    expect(appeal.activeNavRoute.value, RoutePaths.appealManagement);

    final admin = ManagerDashboardController();
    admin.currentRole.value = 'ADMIN';
    admin.navigateToPage(RoutePaths.backupAndRestore);
    expect(admin.activeNavRoute.value, 'homePage');
    admin.navigateToPage(RoutePaths.paymentRecord);
    expect(admin.activeNavRoute.value, RoutePaths.paymentRecord);

    final superAdmin = ManagerDashboardController();
    superAdmin.currentRole.value = 'SUPER_ADMIN';
    superAdmin.navigateToPage(RoutePaths.offenseType);
    expect(superAdmin.activeNavRoute.value, RoutePaths.offenseType);

    final driver = UserDashboardController();
    driver.navigateToPage(RoutePaths.fineInformation);
    driver.navigateToPage(RoutePaths.userManagementPage);
    expect(driver.activeNavRoute.value, RoutePaths.fineInformation);
  });

}

List<String> _labels(ManagerDashboardController controller) {
  return managerShellGroups(
    superAdmin: controller.isSuperAdmin,
    appealReviewer: controller.isAppealReviewer,
  ).expand((group) => group.items).map((item) => item.label).toList();
}
