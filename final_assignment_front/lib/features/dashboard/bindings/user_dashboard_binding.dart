part of '../views/user/user_dashboard.dart';

/// 用户仪表盘绑定类，用于管理用户仪表盘屏幕的控制器依赖。
class UserDashboardBinding extends Bindings {
  /// 注册控制器的依赖关系。
  ///
  /// 在用户仪表盘模块初始化时，此方法将被调用，以确保
  /// 所需的控制器被正确实例化并注入到应用的依赖注入容器中。
  @override
  void dependencies() {
    Get.lazyPut(() => UserDashboardController());
  }
}
