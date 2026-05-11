import 'dart:async';

import 'package:get/get.dart';

abstract class BaseListController<T> extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<T> items = <T>[].obs;

  Future<void> runWithLoading(
    Future<void> Function() action, {
    bool manageLoading = true,
    String Function(Object error)? errorMessageBuilder,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    if (manageLoading) {
      isLoading.value = true;
    }
    errorMessage.value = '';
    try {
      await action();
    } catch (error, stackTrace) {
      errorMessage.value =
          errorMessageBuilder?.call(error) ?? getErrorMessage(error);
      await onError?.call(error, stackTrace);
      await onAsyncError(error, stackTrace);
    } finally {
      if (manageLoading) {
        isLoading.value = false;
      }
    }
  }

  String getErrorMessage(Object error) => error.toString();

  FutureOr<void> onAsyncError(Object error, StackTrace stackTrace) {}

  Future<void> fetchData();

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }
}
