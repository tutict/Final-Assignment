import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/core/auth/auth_service.dart';
import 'package:final_assignment_front/core/auth/user_profile_service.dart';
import 'package:final_assignment_front/core/lifecycle/app_lifecycle_observer.dart';
import 'package:final_assignment_front/core/network/interceptor.dart';
import 'package:final_assignment_front/core/realtime/business_event_listener.dart';
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _configureImageCache();
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
    return GetMaterialApp(
      title: '交通违法行为处理管理系统',
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.login,
      getPages: AppPages.routes,
      theme: AppTheme.basicLight,
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
    Get.lazyPut<OffenseRealtimeService>(
      () => OffenseRealtimeService(),
      fenix: true,
    );
    Get.lazyPut<UserDashboardController>(() => UserDashboardController(),
        fenix: true);
  }
}
