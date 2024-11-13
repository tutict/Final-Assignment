// 声明一个名为AppPages的库
library app_pages;

// 导入各种页面相关的库和绑定
import 'package:final_assignment_front/features/dashboard/views/screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/chat/ai_chat.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/login_screen/login.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/map/map.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/news/news_detail_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/personal_pages/account_and_security/account_and_security_main.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/personal_pages/account_and_security/change_password.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/personal_pages/account_and_security/delete_account.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/personal_pages/account_and_security/information_statement.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/personal_pages/account_and_security/migrate_account.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/personal_pages/consultation_feedback.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/personal_pages/personal_info/change_mobile_phone_number.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/personal_pages/personal_info/personal_info.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/personal_pages/personal_main.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/personal_pages/setting/setting_main.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/process_pages/online_processing_progress.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/scaner/main_scan.dart';
import 'package:final_assignment_front/features/dashboard/bindings/user_dashboard_binding.dart';

// 导入Get库，用于页面路由管理
import 'package:get/get.dart';

// 分割文件，引入app_routes.dart部分
part 'app_routes.dart';

/// AppPages类包含了应用中所有页面的配置和路由信息。
class AppPages {
  // 定义应用启动时的初始页面
  static const initial = Routes.dashboard;

  // 登录页面的路由
  static const login = Routes.login;

  // 用户初始页面路由
  static const userInitial = Routes.userDashboard;

  // AI聊天页面路由
  static const aiChat = Routes.aiChat;

  // 地图页面路由
  static const map = Routes.map;

  // 在线办理进度页面路由
  static const onlineProcessingProgress = Routes.onlineProcessingProgress;

  // 账号与安全页面路由
  static const accountAndSecurity = Routes.accountAndSecurity;

  // 修改密码页面路由
  static const changePassword = Routes.changePassword;

  // 删除账号页面路由
  static const deleteAccount = Routes.deleteAccount;

  // 信息声明页面路由
  static const informationStatement = Routes.informationStatement;

  // 迁移账号页面路由
  static const migrateAccount = Routes.migrateAccount;

  // 修改手机号页面路由
  static const changeMobilePhoneNumber = Routes.changeMobilePhoneNumber;

  // 个人信息页面路由
  static const personalInfo = Routes.personalInfo;

  // 设置页面路由
  static const setting = Routes.setting;

  // 咨询反馈页面路由
  static const consultation = Routes.consultation;

  // 个人主页路由
  static const personalMain = Routes.personalMain;

  // 扫描页面路由
  static const mainScan = Routes.mainScan;

  /// 新闻详情页
  static const newsDetailScreen = Routes.newsDetailScreen;

  // 配置应用中的所有页面路由
  static final routes = [
    GetPage(
      name: _Paths.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: _Paths.dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: _Paths.userDashboard,
      page: () => const UserDashboard(),
      binding: UserDashboardBinding(),
    ),
    GetPage(
      name: _Paths.aiChat,
      page: () => const AIChatPage(),
    ),
    GetPage(
      name: _Paths.map,
      page: () => const MapScreen(),
    ),
    GetPage(
      name: _Paths.onlineProcessingProgress,
      page: () => const OnlineProcessingProgress(),
    ),
    GetPage(
      name: _Paths.accountAndSecurity,
      page: () => const AccountAndSecurityPage(),
    ),
    GetPage(
      name: _Paths.changePassword,
      page: () => const ChangePassword(),
    ),
    GetPage(
      name: _Paths.deleteAccount,
      page: () => const DeleteAccount(),
    ),
    GetPage(
      name: _Paths.informationStatement,
      page: () => const InformationStatementPage(),
    ),
    GetPage(
      name: _Paths.migrateAccount,
      page: () => const MigrateAccount(),
    ),
    GetPage(
      name: _Paths.changeMobilePhoneNumber,
      page: () => const ChangeMobilePhoneNumber(),
    ),
    GetPage(
      name: _Paths.personalInfo,
      page: () => const PersonalInformationPage(),
    ),
    GetPage(
      name: _Paths.setting,
      page: () => const SettingPage(),
    ),
    GetPage(
      name: _Paths.consultation,
      page: () => const ConsultationFeedback(),
    ),
    GetPage(
      name: _Paths.personalMain,
      page: () => const PersonalMainPage(),
    ),
    GetPage(
      name: _Paths.mainScan,
      page: () => const MainScan(),
    ),
    GetPage(
        name: _Paths.newsDetailScreen,
        page: () => const NewsDetailScreen(),
    ),
  ];
}
