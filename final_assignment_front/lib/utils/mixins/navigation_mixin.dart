part of 'app_mixins.dart';

/// 包含所有实例路由的方法。
/// 该 mixin 提供了在应用内导航到不同屏幕或路由的方法。
mixin NavigationMixin {
  /// 根据路由名称返回对应的页面小部件。
  Widget? getPageForRoute(String routeName) {
    switch (routeName) {
      case AppPages.onlineProcessingProgress:
        return const OnlineProcessingProgress();
      case AppPages.map:
        return const MapPage();
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
      default:
        return const Placeholder();
    }
  }
}
