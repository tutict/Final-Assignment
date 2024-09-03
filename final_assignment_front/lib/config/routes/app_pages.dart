import 'package:final_assignment_front/features/dashboard/bindings/user_dashboard_binding.dart';
import 'package:final_assignment_front/features/dashboard/views/screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/screens/user_dashboard_screen.dart';
import 'package:final_assignment_front/features/user_pages/login_screen/login.dart';
import 'package:get/get.dart';

part 'app_routes.dart';

/// contains all configuration pages
class AppPages {
  /// when the app is opened, this page will be the first to be shown
  static const userInitial = Routes.userDashboard;
  static const initial = Routes.dashboard;
  static const login = Routes.login;

  static final routes = [
    GetPage(
      name: _Paths.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: _Paths.dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: _Paths.userDashboard,
      page: () => const UserDashboardScreen(),
      binding: UserDashboardBinding(),
    ),
  ];
}
