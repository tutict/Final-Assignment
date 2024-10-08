import 'package:intl/date_symbol_data_local.dart'; // 只导入本地化日期格式化数据
import 'config/routes/app_pages.dart';
import 'config/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化指定语言环境的日期格式
  await initializeDateFormatting('zh_CN', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '管理系统',
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.userInitial,
      //initialRoute: AppPages.initial,
      //initialRoute: AppPages.login,
      getPages: AppPages.routes,

      builder: (context, child) {
        final currentRoute = Get.currentRoute;

        if (currentRoute == AppPages.initial) {
          return Theme(
            data: AppTheme.basicLight,
            child: child!,
          );
        }

        if (currentRoute == AppPages.userInitial) {
          return Theme(
            data: AppTheme.materialLightTheme,
            child: child!,
          );
        }

        return child!;
      },
    );
  }
}
