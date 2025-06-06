/// app_mixins 库提供了应用程序的一系列混入（mixins）。
/// 包括导航和输入验证功能。
library app_mixins;

import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/components/ai_chat.dart';
import 'package:final_assignment_front/features/dashboard/views/components/change_themes.dart';
import 'package:final_assignment_front/features/dashboard/views/components/map.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/sidebar_management_pages/log_management.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/sidebar_management_pages/manager_business_processing.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/manager_personal_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/manager_setting.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/progress_management.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_pages/sidebar_management_pages/user_management_page.dart' show UserManagementPage;
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/main_process_pages/user_offense_list_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/news/AccidentEvidencePage.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/news/AccidentProgressPage.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/news/AccidentQuickGuidePage.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/news/AccidentVideoQuickPage.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/news/FinePaymentNoticePage.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/news/LatestTrafficViolationNewsPage.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/personal_pages/consultation_feedback.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/personal_pages/personal_main.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/personal_pages/setting/setting_main.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/main_process_pages/business_progress.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/main_process_pages/online_processing_progress.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/scanner/main_scan.dart';
import 'package:flutter/material.dart';


// 引入导航混入功能。
part 'navigation_mixin.dart';

// 引入输入验证混入功能。
part 'validation_input_mixin.dart';

class AppMixins {
}

