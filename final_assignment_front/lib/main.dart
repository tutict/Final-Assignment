import 'package:final_assignment_front/core/theme/theme_controller.dart';
import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/core/auth/auth_service.dart';
import 'package:final_assignment_front/core/auth/user_profile_service.dart';
import 'package:final_assignment_front/core/lifecycle/app_lifecycle_observer.dart';
import 'package:final_assignment_front/core/network/interceptor.dart';
import 'package:final_assignment_front/core/realtime/business_event_listener.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/offense/offense_realtime_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show
        GlobalCupertinoLocalizations,
        GlobalMaterialLocalizations,
        GlobalWidgetsLocalizations;
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/routes/app_pages.dart';
import 'config/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureImageCache();
  final themeController =
      Get.put<ThemeController>(ThemeController(), permanent: true);
  // Await before runApp so the app boots in the correct theme and avoids a
  // cold-start flash from light -> dark.
  await themeController.load();
  runApp(const MainApp());
  _warmUpIntl();
}

void _warmUpIntl() {
  initializeDateFormatting('zh_CN', null).then((_) {
    AppLogger.debug('Date formatting initialized for zh_CN');
  }).catchError((e) {
    AppLogger.error('Failed to initialize date formatting: $e');
  });
}

void _configureImageCache() {
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSizeBytes = 50 << 20;
  imageCache.maximumSize = 200;
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final mode = themeController.themeMode.value;
      return GetMaterialApp(
        title: '交通违法行为处理管理系统',
        debugShowCheckedModeBanner: false,
        initialRoute: AppPages.login,
        getPages: AppPages.routes,
        theme: AppTheme.basicLight,
        darkTheme: AppTheme.basicDark,
        themeMode: mode,
        routingCallback: (routing) {
          if (Get.isRegistered<AppLifecycleObserver>()) {
            Get.find<AppLifecycleObserver>().onRouteChanged(routing);
          }
        },
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0), // Fixed scaling
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        locale: const Locale('zh', 'CN'),
        fallbackLocale: const Locale('en', 'US'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('zh', 'CN'),
        ],
        initialBinding: AppBindings(),
      );
    });
=======
    return GetMaterialApp(
      title: '交通违法行为处理管理系统',
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.login,
      getPages: AppPages.routes,
      theme: AppTheme.basicLight,
      // 全局平滑页面过渡：右侧滑入 + 淡出，替代默认的生硬切换。
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 280),
      routingCallback: (routing) {
        if (Get.isRegistered<AppLifecycleObserver>()) {
          Get.find<AppLifecycleObserver>().onRouteChanged(routing);
        }
      },
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // Fixed scaling
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      locale: const Locale('zh', 'CN'),
      fallbackLocale: const Locale('en', 'US'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('zh', 'CN'),
      ],
      initialBinding: AppBindings(),
    );
>>>>>>> 24855609 (feat(flutter): polish dashboard chrome with motion, shadows, and entrance transitions)
  }
}

class AppBindings extends Bindings {
  @override
  void dependencies() {
    final authService = Get.put<AuthService>(AuthService(), permanent: true);
    Get.put<UserProfileService>(UserProfileService(), permanent: true);
    final apiInterceptor = Get.put<ApiRequestLoggingInterceptor>(
      ApiRequestLoggingInterceptor(authService: authService),
      permanent: true,
    );
    Get.put<AppLifecycleObserver>(
      AppLifecycleObserver(logWriter: apiInterceptor.logWriter)..start(),
      permanent: true,
    );
    Get.put<BusinessEventListener>(
      BusinessEventListener(),
      permanent: true,
    );
    Get.put<ChatController>(
      ChatController(),
      permanent: true,
    );
    Get.lazyPut<OffenseRealtimeService>(
      () => OffenseRealtimeService(),
      fenix: true,
    );
    Get.lazyPut<UserDashboardController>(() => UserDashboardController(),
        fenix: true);
  }
}
