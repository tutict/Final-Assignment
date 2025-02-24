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
      case "businessProgressPage":
        return const Center(child: Text('业务办理页面')); // 示例页面
      case AppPages.personalMain:
        return const PersonalMainPage();
      case AppPages.userSetting:
        return const SettingPage();
      case AppPages.aiChat:
        return const AiChat();
      case AppPages.accountAndSecurity:
        return const AccountAndSecurityPage();
      case AppPages.changePassword:
        return const ChangePassword();
      case AppPages.deleteAccount:
        return const DeleteAccount();
      case AppPages.informationStatement:
        return const InformationStatementPage();
      case AppPages.migrateAccount:
        return const MigrateAccount();
      case AppPages.changeMobilePhoneNumber:
        return const ChangeMobilePhoneNumber();
      case AppPages.personalInfo:
        return const PersonalInformationPage();
      case AppPages.consultation:
        return const ConsultationFeedback();
      case AppPages.mainScan:
        return const MainScan();
      case AppPages.newsDetailScreen:
        return const NewsDetailScreen();
      case AppPages.changeThemes:
        return const ChangeThemes();
      case AppPages.managerSetting:
        return const ManagerSetting();
      case AppPages.managerPersonalPage:
        return const ManagerPersonalPage();
      default:
        debugPrint('Unknown route: $routeName');
        return const Center(child: Text('页面未找到'));
    }
  }
}
