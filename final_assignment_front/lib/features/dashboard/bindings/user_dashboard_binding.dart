part of 'package:final_assignment_front/features/dashboard/views/screens/user_dashboard_screen.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => UserDashboardController());
  }
}
