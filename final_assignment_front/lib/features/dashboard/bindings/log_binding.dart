import 'package:final_assignment_front/features/dashboard/controllers/log_controller.dart';
import 'package:get/get.dart';

class LogBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LogController>(() => LogController(), fenix: true);
  }
}
