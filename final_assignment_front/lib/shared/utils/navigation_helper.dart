import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:get/get.dart';

class NavigationHelper {
  /// Safe named navigation. Falls back to the home route and logs failures.
  static Future<T?> toNamed<T>(
    String routeName, {
    dynamic arguments,
    String fallback = Routes.home,
  }) async {
    try {
      return await Get.toNamed<T>(routeName, arguments: arguments);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Navigation failed: $routeName',
        error: e,
        stackTrace: stackTrace,
      );
      await Get.offNamed(fallback);
      return null;
    }
  }

  static Future<void> offAllNamed(
    String routeName, {
    dynamic arguments,
  }) async {
    try {
      await Get.offAllNamed(routeName, arguments: arguments);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Navigation offAll failed: $routeName',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
