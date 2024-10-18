// 导航到'../views/screens/manager_dashboard_screen.dart'文件以获取更多信息
part of '../views/screens/manager_dashboard_screen.dart';

/// [DashboardBinding]类负责管理[DashboardController]控制器的依赖注入
class DashboardBinding extends Bindings {
  /// 重写[dependencies]方法以注册控制器
  @override
  void dependencies() {
    // 使用Get.lazyPut方法懒加载[DashboardController]实例
    // 懒加载确保了控制器实例仅在第一次请求时被创建，从而优化资源使用
    Get.lazyPut(() => DashboardController());
  }
}
