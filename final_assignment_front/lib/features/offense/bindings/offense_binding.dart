import 'package:final_assignment_front/features/api/offense_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/offense_controller.dart';
import 'package:final_assignment_front/features/offense/repositories/offense_repository.dart';
import 'package:get/get.dart';

class OffenseBinding extends Bindings {
  @override
  void dependencies() {
    registerDependencies();
  }

  static void registerDependencies() {
    _lazyPutIfAbsent<OffenseControllerApi>(
      () => OffenseControllerApi(),
    );
    _lazyPutIfAbsent<OffenseRepository>(
      () => OffenseRepositoryImpl(Get.find()),
    );
    _lazyPutIfAbsent<OffenseController>(
      () => OffenseController(Get.find()),
    );
  }

  static void _lazyPutIfAbsent<T extends Object>(T Function() builder) {
    if (Get.isRegistered<T>() || Get.isPrepared<T>()) return;
    Get.lazyPut<T>(builder, fenix: true);
  }
}
