import 'package:final_assignment_front/features/dashboard/bindings/manager_dashboard_binding.dart';
import 'package:final_assignment_front/features/dashboard/bindings/progress_binding.dart';
import 'package:get/get.dart';

class DashboardProgressBinding extends Bindings {
  @override
  void dependencies() {
    DashboardBinding.registerDependencies();
    ProgressBinding.registerDependencies();
  }
}
