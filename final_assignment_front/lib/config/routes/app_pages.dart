import 'package:final_assignment_front/features/dashboard/views/manager/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/appeal_management.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/driver_list.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/offense_list.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/vehicle_list.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/progress_management.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/sidebar_management/manager_business_processing.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/offense_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/progress_detail.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/business_progress.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/fine_information.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/online_processing_progress.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/user_offense_list_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/vehicle_management.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/news/accident_evidence_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/news/accident_progress_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/news/accident_quick_guide_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/news/accident_video_quick_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/news/fine_payment_notice_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/news/latest_offense_news_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/personal/consultation_feedback.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/personal/personal_main.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/personal/setting/setting_main.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/scanner/main_scan.dart';
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
  static const driverList = Routes.driverList;
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
      page: () => const OnlineProcessingProgress(),
      binding: ProgressBinding(),
    ),
    GetPage(
      name: RoutePaths.userSetting,
      page: () => const SettingPage(),
    ),
    GetPage(
      name: RoutePaths.consultation,
      page: () => const ConsultationFeedback(),
      binding: ProgressBinding(),
    ),
    GetPage(
      name: RoutePaths.personalMain,
      page: () => const PersonalMainPage(),
    ),
    GetPage(
      name: RoutePaths.mainScan,
      page: () => const MainScan(),
    ),
    GetPage(
      name: RoutePaths.appealManagement,
      page: () => const ManagerAppealManagementPage(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.driverList,
      page: () => const DriverListPage(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.offenseList,
      page: () => const OffenseList(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.vehicleList,
      page: () => const VehicleList(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.fineInformation,
      page: () => const FineInformationPage(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.onlineProcessingProgress,
      page: () => const OnlineProcessingProgress(),
      binding: ProgressBinding(),
    ),
    GetPage(
      name: RoutePaths.vehicleManagement,
      page: () => const VehicleManagementPage(),
    ),
    GetPage(
      name: RoutePaths.businessProgress,
      page: () => const BusinessProgressPage(),
    ),
    GetPage(
      name: RoutePaths.managerBusinessProcessing,
      page: () => const ManagerBusinessProcessing(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: RoutePaths.accidentEvidencePage,
      page: () => const AccidentEvidencePage(),
    ),
    GetPage(
      name: RoutePaths.accidentProgressPage,
      page: () => const AccidentProgressPage(),
    ),
    GetPage(
      name: RoutePaths.accidentQuickGuidePage,
      page: () => const AccidentQuickGuidePage(),
    ),
    GetPage(
      name: RoutePaths.accidentVideoQuickPage,
      page: () => const AccidentVideoQuickPage(),
    ),
    GetPage(
      name: RoutePaths.finePaymentNoticePage,
      page: () => const FinePaymentNoticePage(),
    ),
    GetPage(
      name: RoutePaths.latestOffenseNewsPage,
      page: () => const LatestOffenseNewsPage(),
    ),
    GetPage(
      name: RoutePaths.progressManagement,
      page: () => const ProgressManagementPage(),
      binding: DashboardProgressBinding(),
    ),
    GetPage(
      name: RoutePaths.progressDetailPage,
      page: () => ProgressDetailPage(
        item: Get.arguments as ProgressItem,
      ),
      binding: ProgressBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: RoutePaths.userOffenseListPage,
      page: () => const UserOffenseListPage(),
    ),
    GetPage(
      name: RoutePaths.offenseScreen,
      page: () => const OffenseScreen(),
      binding: OffenseBinding(),
    ),
    GetPage(
      name: RoutePaths.progressManagementPage,
      page: () => const ProgressManagementPage(),
      binding: DashboardProgressBinding(),
    ),
    ...AdminPages.routes,
  ];
}
