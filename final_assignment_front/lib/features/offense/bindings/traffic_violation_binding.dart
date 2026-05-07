import 'package:final_assignment_front/features/api/traffic_violation_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/traffic_violation_controller.dart';
import 'package:final_assignment_front/features/offense/repositories/traffic_violation_repository.dart';
import 'package:get/get.dart';

class TrafficViolationBinding extends Bindings {
  @override
  void dependencies() {
    registerDependencies();
  }

  static void registerDependencies() {
    _lazyPutIfAbsent<TrafficViolationControllerApi>(
      () => TrafficViolationControllerApi(),
    );
    _lazyPutIfAbsent<TrafficViolationRepository>(
      () => TrafficViolationRepositoryImpl(Get.find()),
    );
    _lazyPutIfAbsent<TrafficViolationController>(
      () => TrafficViolationController(Get.find()),
    );
  }

  static void _lazyPutIfAbsent<T extends Object>(T Function() builder) {
    if (Get.isRegistered<T>() || Get.isPrepared<T>()) return;
    Get.lazyPut<T>(builder, fenix: true);
  }
}
