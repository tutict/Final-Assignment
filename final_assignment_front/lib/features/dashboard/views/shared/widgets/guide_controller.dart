import 'package:get/get.dart';

class GuideController {
  static final RxnString guideId = RxnString();

  static void open(String id) => guideId.value = id;

  static void close() => guideId.value = null;
}
