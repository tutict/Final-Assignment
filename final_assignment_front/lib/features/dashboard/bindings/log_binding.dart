import 'package:final_assignment_front/features/dashboard/controllers/log_controller.dart';
import 'package:get/Get.dart';

class LogBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LogController());
  }
}
