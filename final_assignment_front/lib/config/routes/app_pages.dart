library app_pages;

import 'package:final_assignment_front/features/dashboard/views/screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/user_pages/login_screen/login.dart';
import 'package:final_assignment_front/features/user_pages/chat/ai_chat.dart';
import 'package:final_assignment_front/features/user_pages/map/map.dart';
import 'package:final_assignment_front/features/user_pages/online_processing_progress.dart';
import 'package:final_assignment_front/features/user_pages/personal/account_and_security/account_and_security_main.dart';
import 'package:final_assignment_front/features/user_pages/personal/account_and_security/change_password.dart';
import 'package:final_assignment_front/features/user_pages/personal/account_and_security/delete_account.dart';
import 'package:final_assignment_front/features/user_pages/personal/account_and_security/information_statement.dart';
import 'package:final_assignment_front/features/user_pages/personal/account_and_security/migrate_account.dart';
import 'package:final_assignment_front/features/user_pages/personal/consultation_feedback.dart';
import 'package:final_assignment_front/features/user_pages/personal/personal_info/change_mobile_phone_number.dart';
import 'package:final_assignment_front/features/user_pages/personal/personal_info/personal_info.dart';
import 'package:final_assignment_front/features/user_pages/personal/personal_main.dart';
import 'package:final_assignment_front/features/user_pages/personal/setting/setting_main.dart';
import 'package:final_assignment_front/features/user_pages/scaner/main_scan.dart';
import 'package:final_assignment_front/features/dashboard/bindings/user_dashboard_binding.dart';

import 'package:get/get.dart';

part 'app_routes.dart';

/// contains all configuration pages
class AppPages {
  /// when the app is opened, this page will be the first to be shown
  static const initial = Routes.dashboard;
  static const login = Routes.login;
  static const userInitial = Routes.userDashboard;
  static const aiChat = Routes.aiChat;
  static const map = Routes.map;
  static const onlineProcessingProgress = Routes.onlineProcessingProgress;
  static const accountAndSecurity = Routes.accountAndSecurity;
  static const changePassword = Routes.changePassword;
  static const deleteAccount = Routes.deleteAccount;
  static const informationStatement = Routes.informationStatement;
  static const migrateAccount = Routes.migrateAccount;
  static const changeMobilePhoneNumber = Routes.changeMobilePhoneNumber;
  static const personalInfo = Routes.personalInfo;
  static const setting = Routes.setting;
  static const consultation = Routes.consultation;
  static const personalMain = Routes.personalMain;
  static const mainScan = Routes.mainScan;

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
      page: () => const PersonalInfoPage(),
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
  ];
}
