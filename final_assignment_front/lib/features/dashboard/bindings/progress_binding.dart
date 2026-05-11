import 'package:final_assignment_front/features/dashboard/controllers/progress_controller.dart';
import 'package:get/get.dart';

class ProgressBinding extends Bindings {
  @override
  void dependencies() {
    registerDependencies();
  }

  static void registerDependencies() {
    if (Get.isRegistered<ProgressController>() ||
        Get.isPrepared<ProgressController>()) {
      return;
    }
    Get.lazyPut<ProgressController>(() => ProgressController());
  }
}
