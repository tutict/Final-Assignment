import 'package:final_assignment_front/features/dashboard/bindings/user_dashboard_binding.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard_screen.dart';
import 'package:get/get.dart';

part 'user_app_routes.dart';

/// contains all configuration pages
class UserAppPages {
  /// when the app is opened, this page will be the first to be shown
  static const userInitial = UserRoutes.userDashboard;

  static final routes = [
    GetPage(
      name: _UserPaths.userDashboard,
      page: () => const UserDashboard(),
      binding: UserDashboardBinding(),
    ),
  ];
}
