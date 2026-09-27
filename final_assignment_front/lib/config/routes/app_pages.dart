import 'package:final_assignment_front/features/dashboard/views/manager/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/progress_detail.dart';
import 'package:final_assignment_front/features/dashboard/views/user/user_dashboard.dart';
import 'package:final_assignment_front/features/login_screen/login.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:final_assignment_front/features/dashboard/bindings/dashboard_progress_binding.dart';
import 'package:final_assignment_front/features/dashboard/bindings/manager_dashboard_binding.dart';
import 'package:final_assignment_front/features/dashboard/bindings/progress_binding.dart';
import 'package:final_assignment_front/features/dashboard/bindings/user_dashboard_binding.dart';
import 'package:final_assignment_front/features/offense/bindings/offense_binding.dart';
import 'package:get/get.dart';

import 'admin_pages.dart';
import 'app_routes.dart';
import 'shell_redirect.dart';

class AppPages {
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
  static const userSetting = Routes.userSetting;
  static const consultation = Routes.consultation;
  static const personalMain = Routes.personalMain;
  static const mainScan = Routes.mainScan;
  static const newsDetailScreen = Routes.newsDetailScreen;
  static const appealManagement = Routes.appealManagement;
  static const backupAndRestore = Routes.backupAndRestore;
  static const deductionManagement = Routes.deductionManagement;
  static const driverList = Routes.driverList;
  static const fineList = Routes.fineList;
  static const managerPersonalPage = Routes.managerPersonalPage;
  static const managerSetting = Routes.managerSetting;
  static const offenseList = Routes.offenseList;
  static const vehicleList = Routes.vehicleList;
  static const fineInformation = Routes.fineInformation;
  static const onlineProcessing = Routes.onlineProcessing;
  static const userAppeal = Routes.userAppeal;
  static const vehicleManagement = Routes.vehicleManagement;
  static const changeThemes = Routes.changeThemes;
  static const businessProgress = Routes.businessProgress;
  static const managerBusinessProcessing = Routes.managerBusinessProcessing;
  static const accidentEvidencePage = Routes.accidentEvidencePage;
  static const accidentProgressPage = Routes.accidentProgressPage;
  static const accidentQuickGuidePage = Routes.accidentQuickGuidePage;
  static const accidentVideoQuickPage = Routes.accidentVideoQuickPage;
  static const finePaymentNoticePage = Routes.finePaymentNoticePage;
  static const latestOffenseNewsPage = Routes.latestOffenseNewsPage;
  static const progressManagement = Routes.progressManagement;
  static const progressDetailPage = Routes.progressDetailPage;
  static const logManagement = Routes.logManagement;
  static const userManagementPage = Routes.userManagementPage;
  static const loginLogPage = Routes.loginLogPage;
  static const operationLogPage = Routes.operationLogPage;
  static const systemLogPage = Routes.systemLogPage;
  static const userOffenseListPage = Routes.userOffenseListPage;
  static const offenseScreen = Routes.offenseScreen;
  static const progressManagementPage = Routes.progressManagementPage;

  static final routes = [
    GetPage(
      name: RoutePaths.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: RoutePaths.dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.userDashboard,
      page: () => const UserDashboard(),
      binding: UserDashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.onlineProcessingProgress,
      page: () => const ShellRedirect(page: RoutePaths.onlineProcessingProgress, forceUser: true),
      binding: ProgressBinding(),
    ),
    GetPage(
      name: RoutePaths.userSetting,
      page: () => const ShellRedirect(page: RoutePaths.userSetting, forceUser: true),
    ),
    GetPage(
      name: RoutePaths.consultation,
      page: () => const ShellRedirect(page: RoutePaths.consultation, forceUser: true),
      binding: ProgressBinding(),
    ),
    GetPage(
      name: RoutePaths.personalMain,
      page: () => const ShellRedirect(page: RoutePaths.personalMain, forceUser: true),
    ),
    GetPage(
      name: RoutePaths.accountAndSecurity,
      page: () => const ShellRedirect(page: RoutePaths.userSetting, forceUser: true),
    ),
    GetPage(
      name: RoutePaths.changePassword,
      page: () => const ShellRedirect(page: RoutePaths.userSetting, forceUser: true),
    ),
    GetPage(
      name: RoutePaths.deleteAccount,
      page: () => const ShellRedirect(page: RoutePaths.userSetting, forceUser: true),
    ),
    GetPage(
      name: RoutePaths.informationStatement,
      page: () => const ShellRedirect(page: RoutePaths.userSetting, forceUser: true),
    ),
    GetPage(
      name: RoutePaths.migrateAccount,
      page: () => const ShellRedirect(page: RoutePaths.userSetting, forceUser: true),
    ),
    GetPage(
      name: RoutePaths.changeMobilePhoneNumber,
      page: () => const ShellRedirect(page: RoutePaths.personalMain, forceUser: true),
    ),
    GetPage(
      name: RoutePaths.personalInfo,
      page: () => const ShellRedirect(page: RoutePaths.personalMain, forceUser: true),
    ),
    GetPage(
      name: RoutePaths.mainScan,
      page: () => const ShellRedirect(page: RoutePaths.mainScan, forceUser: true),
    ),
    GetPage(
      name: RoutePaths.appealManagement,
      page: () => const ShellRedirect(page: RoutePaths.appealManagement, forceManager: true),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.driverList,
      page: () => const ShellRedirect(page: RoutePaths.driverList, forceManager: true),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.deductionManagement,
      page: () => const ShellRedirect(page: RoutePaths.deductionManagement, forceManager: true),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.fineList,
      page: () => const ShellRedirect(page: RoutePaths.fineList, forceManager: true),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.offenseList,
      page: () => const ShellRedirect(page: RoutePaths.offenseList, forceManager: true),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.vehicleList,
      page: () => const ShellRedirect(page: RoutePaths.vehicleList, forceManager: true),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.fineInformation,
      page: () => const ShellRedirect(page: RoutePaths.fineInformation, forceUser: true),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.onlineProcessingProgress,
      page: () => const ShellRedirect(page: RoutePaths.onlineProcessingProgress, forceUser: true),
      binding: ProgressBinding(),
    ),
    GetPage(
      name: RoutePaths.vehicleManagement,
      page: () => const ShellRedirect(page: RoutePaths.vehicleManagement, forceUser: true),
    ),
    GetPage(
      name: RoutePaths.businessProgress,
      page: () => const ShellRedirect(home: true, forceUser: true),
    ),
    GetPage(
      name: RoutePaths.userChangeThemes,
      page: () => const ShellRedirect(
        page: RoutePaths.userSetting,
        forceUser: true,
        section: 'appearance',
      ),
    ),
    GetPage(
      name: RoutePaths.trafficViolationScreen,
      page: () => const ShellRedirect(home: true, forceManager: true),
    ),
    GetPage(
      name: RoutePaths.managerBusinessProcessing,
      page: () => const ShellRedirect(home: true, forceManager: true),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.accidentEvidencePage,
      page: () => const ShellRedirect(page: RoutePaths.userOffenseListPage, guide: 'evidence', forceUser: true),
    ),
    GetPage(
      name: RoutePaths.accidentProgressPage,
      page: () => const ShellRedirect(page: RoutePaths.userOffenseListPage, guide: 'flow', forceUser: true),
    ),
    GetPage(
      name: RoutePaths.accidentQuickGuidePage,
      page: () => const ShellRedirect(page: RoutePaths.userOffenseListPage, guide: 'quick', forceUser: true),
    ),
    GetPage(
      name: RoutePaths.accidentVideoQuickPage,
      page: () => const ShellRedirect(page: RoutePaths.userOffenseListPage, guide: 'video', forceUser: true),
    ),
    GetPage(
      name: RoutePaths.finePaymentNoticePage,
      page: () => const ShellRedirect(page: RoutePaths.fineInformation, guide: 'payment', forceUser: true),
    ),
    GetPage(
      name: RoutePaths.latestOffenseNewsPage,
      page: () => const ShellRedirect(home: true, guide: 'news', forceUser: true),
    ),
    GetPage(
      name: RoutePaths.progressManagement,
      page: () => const ShellRedirect(page: RoutePaths.progressManagement, forceManager: true),
      binding: DashboardProgressBinding(),
    ),
    GetPage(
      name: RoutePaths.progressDetailPage,
      page: () {
        final args = Get.arguments;
        if (args is ProgressItem) {
          return ProgressDetailPage(item: args);
        }
        return const MissingProgressDetailPage();
      },
      binding: ProgressBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: RoutePaths.userOffenseListPage,
      page: () => const ShellRedirect(page: RoutePaths.userOffenseListPage, forceUser: true),
    ),
    GetPage(
      name: RoutePaths.offenseScreen,
      page: () => const ShellRedirect(home: true, forceManager: true),
      binding: OffenseBinding(),
    ),
    GetPage(
      name: RoutePaths.progressManagementPage,
      page: () => const ShellRedirect(page: RoutePaths.progressManagement, forceManager: true),
      binding: DashboardProgressBinding(),
    ),

    GetPage(
      name: RoutePaths.userAppeal,
      page: () => const ShellRedirect(page: RoutePaths.userAppeal, forceUser: true),
    ),
    GetPage(
      name: RoutePaths.paymentRecord,
      page: () => const ShellRedirect(page: RoutePaths.paymentRecord, forceManager: true),
    ),
    GetPage(
      name: RoutePaths.offenseType,
      page: () => const ShellRedirect(page: RoutePaths.offenseType, forceManager: true),
    ),
    GetPage(
      name: RoutePaths.roleManagement,
      page: () => const ShellRedirect(page: RoutePaths.roleManagement, forceManager: true),
    ),
    GetPage(
      name: RoutePaths.permissionManagement,
      page: () => const ShellRedirect(page: RoutePaths.permissionManagement, forceManager: true),
    ),
    GetPage(
      name: RoutePaths.systemSettings,
      page: () => const ShellRedirect(page: RoutePaths.systemSettings, forceManager: true),
    ),
    GetPage(
      name: RoutePaths.requestHistory,
      page: () => const ShellRedirect(page: RoutePaths.requestHistory, forceManager: true),
    ),
    GetPage(
      name: RoutePaths.onlineProcessing,
      page: () => const ShellRedirect(page: RoutePaths.onlineProcessingProgress, forceUser: true),
    ),
    ...AdminPages.routes,
  ];
}
