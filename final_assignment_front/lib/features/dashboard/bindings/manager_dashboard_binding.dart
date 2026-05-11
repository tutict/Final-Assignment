import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/offense/bindings/deduction_binding.dart';
import 'package:final_assignment_front/features/offense/bindings/traffic_violation_binding.dart';
import 'package:final_assignment_front/features/vehicle/bindings/vehicle_binding.dart';
import 'package:get/get.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    registerDependencies();
  }

  static void registerDependencies() {
    if (!Get.isRegistered<DashboardController>() &&
        !Get.isPrepared<DashboardController>()) {
      Get.lazyPut<DashboardController>(() => DashboardController());
    }
    DeductionBinding.registerDependencies();
    TrafficViolationBinding.registerDependencies();
    VehicleBinding.registerDependencies();
  }
}
