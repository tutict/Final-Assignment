
import 'package:final_assignment_front/features/dashboard/views/manager/pages/backup_and_restore_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/logs/login_log_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/logs/operation_log_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/logs/system_log_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/deduction_management_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/driver_list_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/fine_list_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/manager_appeal_management_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/offense_list.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/vehicle_list.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/manager_personal_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/manager_setting_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/sidebar_management/user_management_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/system/system_record_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/fine_information.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/user_appeal.dart';
import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/progress_management.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/sidebar_management/manager_business_processing.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/sidebar_management/rag_management_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/sidebar_management/system_governance.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/map.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/business_progress.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/online_processing_progress.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/user_offense_list_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/vehicle_management_page.dart';
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
import 'package:flutter/material.dart';

Widget? resolveDashboardPage(String routeName) {
  switch (routeName) {
    case 'homePage':
      return const SizedBox.shrink();
    case Routes.onlineProcessingProgress:
      return const OnlineProcessingProgress();
    case Routes.businessProgress:
      return const BusinessProgressPage();
    case Routes.personalMain:
      return const PersonalMainPage();
    case Routes.map:
      return const MapPage();
    case Routes.userSetting:
      return const SettingPage();
    case Routes.consultation:
      return const ConsultationFeedback();
    case Routes.mainScan:
      return const MainScan();
    case Routes.managerBusinessProcessing:
      return const ManagerBusinessProcessing();
    case Routes.systemGovernance:
      return const SystemGovernancePage();
    case Routes.ragManagement:
      return const RagManagementPage();
    case Routes.accidentEvidencePage:
      return const AccidentEvidencePage();
    case Routes.accidentVideoQuickPage:
      return const AccidentVideoQuickPage();
    case Routes.accidentQuickGuidePage:
      return const AccidentQuickGuidePage();
    case Routes.accidentProgressPage:
      return const AccidentProgressPage();
    case Routes.finePaymentNoticePage:
      return const FinePaymentNoticePage();
    case Routes.latestOffenseNewsPage:
      return const LatestOffenseNewsPage();
    case Routes.progressManagement:
      return const ProgressManagementPage();
    case Routes.userOffenseListPage:
      return const UserOffenseListPage();
    case Routes.userAppeal:
      return const UserAppealPage();
    case Routes.fineInformation:
      return const FineInformationPage();
    case Routes.vehicleManagement:
      return const VehicleManagementPage();
    case Routes.offenseList:
      return const OffenseList();
    case Routes.fineList:
      return const FineListPage();
    case Routes.deductionManagement:
      return const DeductionManagementPage();
    case Routes.appealManagement:
      return const ManagerAppealManagementPage();
    case Routes.driverList:
      return const DriverListPage();
    case Routes.vehicleList:
      return const VehicleList();
    case Routes.paymentRecord:
      return const PaymentRecordsPage();
    case Routes.offenseType:
      return const OffenseTypeRecordsPage();
    case Routes.roleManagement:
      return const RoleRecordsPage();
    case Routes.permissionManagement:
      return const PermissionRecordsPage();
    case Routes.systemSettings:
      return const SystemSettingsRecordsPage();
    case Routes.requestHistory:
      return const RequestHistoryPage();
    case Routes.backupAndRestore:
      return const BackupAndRestorePage();
    case Routes.userManagementPage:
      return const UserManagementPage();
    case Routes.loginLogPage:
      return const LoginLogPage();
    case Routes.operationLogPage:
      return const OperationLogPage();
    case Routes.systemLogPage:
      return const SystemLogPage();
    case Routes.managerPersonalPage:
      return const ManagerPersonalPage();
    case Routes.managerSetting:
    case Routes.changeThemes:
      return const ManagerSettingPage();
    default:
      AppLogger.debug('Unknown route: $routeName');
      return const Center(child: Text('Page not found'));
  }
}
