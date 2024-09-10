import 'package:final_assignment_front/features/dashboard/bindings/user_dashboard_binding.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
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
import 'package:get/get.dart';

part 'user_app_routes.dart';

/// contains all configuration pages
class UserAppPages {
  /// when the app is opened, this page will be the first to be shown
  static const userInitial = UserRoutes.userDashboard;
  static const aiChat = UserRoutes.aiChat;
  static const map = UserRoutes.map;
  static const onlineProcessingProgress = UserRoutes.onlineProcessingProgress;
  static const accountAndSecurity = UserRoutes.accountAndSecurity;
  static const changePassword = UserRoutes.changePassword;
  static const deleteAccount = UserRoutes.deleteAccount;
  static const informationStatement = UserRoutes.informationStatement;
  static const migrateAccount = UserRoutes.migrateAccount;
  static const changeMobilePhoneNumber = UserRoutes.changeMobilePhoneNumber;
  static const personalInfo = UserRoutes.personalInfo;
  static const setting = UserRoutes.setting;
  static const consultation = UserRoutes.consultation;
  static const personalMain = UserRoutes.personalMain;
  static const mainScan = UserRoutes.mainScan;

  static final routes = [
    GetPage(
      name: _UserPaths.userDashboard,
      page: () => const UserDashboard(),
      binding: UserDashboardBinding(),
    ),
    GetPage(
        name: _UserPaths.aiChat,
        page: () => const AIChatPage(),
    ),
    GetPage(
        name: _UserPaths.map,
        page: () => const MapScreen(),
    ),
    GetPage(
        name: _UserPaths.onlineProcessingProgress,
        page: () => const OnlineProcessingProgress(),
    ),
    GetPage(
      name: _UserPaths.accountAndSecurity,
      page: () => const AccountAndSecurityPage(),
    ),
    GetPage(
      name: _UserPaths.changePassword,
      page: () => const ChangePassword(),
    ),
    GetPage(
        name: _UserPaths.deleteAccount,
        page: () => const DeleteAccount(),
    ),
    GetPage(
        name: _UserPaths.informationStatement,
        page: () => const InformationStatementPage(),
    ),
    GetPage(
        name: _UserPaths.migrateAccount,
        page: () => const MigrateAccount(),
    ),
    GetPage(
        name: _UserPaths.changeMobilePhoneNumber,
        page: () => const ChangeMobilePhoneNumber(),
    ),
    GetPage(
        name: _UserPaths.personalInfo,
        page: () => const PersonalInfoPage(),
    ),
    GetPage(
        name: _UserPaths.setting,
        page: () => const SettingPage(),
    ),
    GetPage(
        name: _UserPaths.consultation,
        page: () => const ConsultationFeedback(),
    ),
    GetPage(
        name: _UserPaths.personalMain,
        page: () => const PersonalMainPage(),
    ),
    GetPage(
        name: _UserPaths.mainScan,
        page: () => const MainScan(),
    ),
  ];
}
