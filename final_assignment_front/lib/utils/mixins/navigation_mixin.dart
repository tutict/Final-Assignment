part of 'app_mixins.dart';

mixin NavigationMixin {
  Widget? getPageForRoute(String routeName) {
    switch (routeName) {
      case "homePage":
        return const SizedBox.shrink(); // 主页返回空视图，显示默认内容
      case AppPages.onlineProcessingProgress:
        return const OnlineProcessingProgress();
      case AppPages.map:
        return const MapPage();
      case AppPages.businessProgress:
        return const BusinessProgressPage();
      case AppPages.personalMain:
        return const PersonalMainPage();
      case AppPages.userSetting:
        return const SettingPage();
      case AppPages.aiChat:
        return const AiChat();
      case AppPages.consultation:
        return const ConsultationFeedback();
      case AppPages.mainScan:
        return const MainScan();
      case AppPages.changeThemes:
        return const ChangeThemes();
      case AppPages.managerSetting:
        return const ManagerSetting();
      case AppPages.managerPersonalPage:
        return const ManagerPersonalPage();
      case AppPages.managerBusinessProcessing:
        return const ManagerBusinessProcessing();
      case AppPages.accidentEvidencePage:
        return const AccidentEvidencePage();
      case AppPages.accidentVideoQuickPage:
        return const AccidentVideoQuickPage();
      case AppPages.accidentQuickGuidePage:
        return const AccidentQuickGuidePage();
      case AppPages.accidentProgressPage:
        return const AccidentProgressPage();
      case AppPages.finePaymentNoticePage:
        return const FinePaymentNoticePage();
      case AppPages.latestTrafficViolationNewsPage:
        return const LatestTrafficViolationNewsPage();
      case AppPages.progressManagement:
        return const ProgressManagementPage();
      case AppPages.logManagement:
        return const LogManagement();
      case AppPages.userManagementPage:
        return const UserManagementPage();
      case AppPages.userOffenseListPage:
        return const UserOffenseListPage();
      default:
        debugPrint('Unknown route: $routeName');
        return const Center(child: Text('页面未找到'));
    }
  }
}
