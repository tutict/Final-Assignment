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
    default:
      AppLogger.debug('Unknown route: $routeName');
      return const Center(child: Text('Page not found'));
  }
}
