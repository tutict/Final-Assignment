import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:get/Get.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ChatController());
  }
}
