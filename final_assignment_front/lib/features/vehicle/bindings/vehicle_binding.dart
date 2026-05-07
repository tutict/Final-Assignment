import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/vehicle_controller.dart';
import 'package:final_assignment_front/features/vehicle/repositories/vehicle_repository.dart';
import 'package:get/get.dart';

class VehicleBinding extends Bindings {
  @override
  void dependencies() {
    registerDependencies();
  }

  static void registerDependencies() {
    _lazyPutIfAbsent<VehicleInformationControllerApi>(
      () => VehicleInformationControllerApi(),
    );
    _lazyPutIfAbsent<VehicleRepository>(
      () => VehicleRepositoryImpl(Get.find()),
    );
    _lazyPutIfAbsent<VehicleController>(
      () => VehicleController(Get.find()),
    );
  }

  static void _lazyPutIfAbsent<T extends Object>(T Function() builder) {
    if (Get.isRegistered<T>() || Get.isPrepared<T>()) return;
    Get.lazyPut<T>(builder, fenix: true);
  }
}
