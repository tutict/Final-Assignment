import 'package:final_assignment_front/features/dashboard/controllers/log_controller.dart';
import 'package:get/get.dart';

class LogBinding extends Bindings {
  @override
  void dependencies() {
    registerDependencies();
  }

  static void registerDependencies() {
    if (Get.isRegistered<LogController>() || Get.isPrepared<LogController>()) {
      return;
    }
    Get.lazyPut<LogController>(() => LogController(), fenix: true);
  }
}
