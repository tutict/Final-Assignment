import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/features/dashboard/controllers/progress_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/routes/app_pages.dart';
import 'config/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting with error handling
  try {
    await initializeDateFormatting('zh_CN', null);
    debugPrint('Date formatting initialized for zh_CN');
  } catch (e) {
    debugPrint('Failed to initialize date formatting: $e');
  }

  Get.put(DashboardController());
  Get.put(UserDashboardController());
  Get.put(ChatController());
  Get.put(ProgressController());

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '交通违法行为处理管理系统',
      // Updated to match your app's context
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.login,
      // Consistent entry point
      getPages: AppPages.routes,
      // Routes defined in AppPages
      theme: AppTheme.basicLight,
      // Default theme
      builder: (context, child) {
        return MediaQuery(
          // Prevent font scaling based on system settings
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // Fixed scaling
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      // Optional: Add localization support if needed
      locale: const Locale('zh', 'CN'),
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}
