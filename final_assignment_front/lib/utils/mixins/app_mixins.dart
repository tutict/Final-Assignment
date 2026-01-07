/// app_mixins 库提供了应用程序的一系列混入（mixins）。
/// 包括导航和输入验证功能。
library app_mixins;

import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/ai_chat.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/change_themes.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/map.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/sidebar_management/log_management.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/sidebar_management/manager_business_processing.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/manager_personal_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/manager_setting.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/progress_management.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/sidebar_management/user_management_page.dart' show UserManagementPage;
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/user_offense_list_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/news/accident_evidence_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/news/accident_progress_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/news/accident_quick_guide_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/news/accident_video_quick_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/news/fine_payment_notice_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/news/latest_traffic_violation_news_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/personal/consultation_feedback.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/personal/personal_main.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/personal/setting/setting_main.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/business_progress.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/online_processing_progress.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/scanner/main_scan.dart';
import 'package:flutter/material.dart';


// 引入导航混入功能。
part 'navigation_mixin.dart';

// 引入输入验证混入功能。
part 'validation_input_mixin.dart';

class AppMixins {
}

