import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/offense/bindings/deduction_binding.dart';
import 'package:final_assignment_front/features/offense/bindings/offense_binding.dart';
import 'package:final_assignment_front/features/vehicle/bindings/vehicle_binding.dart';
import 'package:get/get.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    registerDependencies();
  }

  static void registerDependencies() {
    if (!Get.isRegistered<ManagerDashboardController>() &&
        !Get.isPrepared<ManagerDashboardController>()) {
      Get.lazyPut<ManagerDashboardController>(
          () => ManagerDashboardController());
    }
    DeductionBinding.registerDependencies();
    OffenseBinding.registerDependencies();
    VehicleBinding.registerDependencies();
  }
}
