import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/features/dashboard/controllers/progress_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show
        GlobalCupertinoLocalizations,
        GlobalMaterialLocalizations,
        GlobalWidgetsLocalizations; // 添加此导入
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
  final progressController = Get.put(ProgressController());
  await progressController.initialize();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '交通违法行为处理管理系统',
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.login,
      getPages: AppPages.routes,
      theme: AppTheme.basicLight,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // Fixed scaling
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      locale: const Locale('zh', 'CN'),
      // 默认中文
      fallbackLocale: const Locale('en', 'US'),
      // 回退英文
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // 英文
        Locale('zh', 'CN'), // 中文
      ],
    );
  }
}
