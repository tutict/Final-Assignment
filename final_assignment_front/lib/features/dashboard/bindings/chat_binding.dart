import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiChatBinding extends Bindings {
  @override
  void dependencies() {
    registerDependencies();
  }

  static void registerDependencies() {
    if (!Get.isRegistered<ChatController>() &&
        !Get.isPrepared<ChatController>()) {
      Get.lazyPut<ChatController>(() => ChatController());
    }
    _syncUserRole();
  }

  static void _syncUserRole() {
    SharedPreferences.getInstance().then((prefs) {
      final role = prefs.getString('userRole');
      if (role == null || role.isEmpty) {
        return;
      }
      Get.find<ChatController>().setUserRole(role);
    });
  }
}
