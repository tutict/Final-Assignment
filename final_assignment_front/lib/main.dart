import 'package:final_assignment_front/utils/services/message_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        // 可以在这里添加其他 Provider
      ],
      child: GetMaterialApp(
        title: '管理系统',
        debugShowCheckedModeBanner: false,
        initialRoute: AppPages.userInitial,
        getPages: AppPages.routes,
        theme: AppTheme.basicLight,
        builder: (context, child) {
          return MediaQuery(
            // 确保字体大小不随系统设置而改变
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.noScaling),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
