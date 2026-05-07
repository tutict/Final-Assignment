import 'package:final_assignment_front/features/api/deduction_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/deduction_controller.dart';
import 'package:final_assignment_front/features/offense/repositories/deduction_repository.dart';
import 'package:get/get.dart';

class DeductionBinding extends Bindings {
  @override
  void dependencies() {
    registerDependencies();
  }

  static void registerDependencies() {
    _lazyPutIfAbsent<DeductionInformationControllerApi>(
      () => DeductionInformationControllerApi(),
    );
    _lazyPutIfAbsent<DeductionRepository>(
      () => DeductionRepositoryImpl(Get.find()),
    );
    _lazyPutIfAbsent<DeductionController>(
      () => DeductionController(Get.find()),
    );
  }

  static void _lazyPutIfAbsent<T extends Object>(T Function() builder) {
    if (Get.isRegistered<T>() || Get.isPrepared<T>()) return;
    Get.lazyPut<T>(builder, fenix: true);
  }
}
