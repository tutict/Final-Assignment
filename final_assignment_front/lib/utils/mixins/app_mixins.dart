/// app_mixins 库提供了应用程序的一系列混入（mixins）。
/// 包括导航和输入验证功能。
library app_mixins;

import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/dashboard/views/components/change_themes.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/chat/ai_chat.dart';
// import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/map/map.dart';
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
import 'package:flutter/material.dart';

// 引入导航混入功能。
part 'navigation_mixin.dart';

// 引入输入验证混入功能。
part 'validation_input_mixin.dart';

class AppMixins {
}

