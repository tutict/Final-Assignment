import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/routes/app_pages.dart';
import 'config/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化指定语言环境的日期格式
  await initializeDateFormatting('zh_CN', null);

  Get.put(DashboardController());
  Get.put(UserDashboardController());
  Get.put(ChatController());

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '管理系统',
      debugShowCheckedModeBanner: false,
      // initialRoute: AppPages.initial,
      // initialRoute: AppPages.userInitial,
      initialRoute: AppPages.login,
      getPages: AppPages.routes,
      theme: AppTheme.basicLight,
      builder: (context, child) {
        return MediaQuery(
          // 确保字体大小不随系统设置而改变
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
