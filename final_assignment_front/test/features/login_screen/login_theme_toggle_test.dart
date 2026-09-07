import 'package:final_assignment_front/config/themes/app_theme.dart';
import 'package:final_assignment_front/core/theme/theme_controller.dart';
import 'package:final_assignment_front/features/login_screen/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Get.reset();
    Get.put<ThemeController>(ThemeController(), permanent: true);
  });

  tearDown(Get.reset);

  testWidgets('登录页主题按钮会立即刷新整个登录界面', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.trafficEnforcementLight,
        darkTheme: AppTheme.trafficEnforcementDark,
        home: const LoginScreen(),
      ),
    );
    await tester.pump();

    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.light,
    );

    await tester.tap(find.byTooltip('切换到深色模式'));
    await tester.pump();

    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
      reason: '主题按钮应立即让登录页的背景、表单和文字使用深色主题',
    );
  });
}
