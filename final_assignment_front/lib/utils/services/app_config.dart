/// AppConfig类用于集中管理应用程序的配置常量，
/// 包括API的基础URL和各个功能模块的API端点。
class AppConfig {
  /// 基础URL用于构建完整的API请求地址。
  static const String baseUrl = 'http://localhost:8082';

  /// 获取完整的API请求地址
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// 上诉管理模块的API端点。
  static const String appealManagementEndpoint = '/eventbus/appeals';

  /// 备份与恢复模块的API端点。
  static const String backupRestoreEndpoint = '/eventbus/backup';

  /// 司机信息管理模块的API端点。
  static const String driverInformationEndpoint = '/eventbus/drivers';

  /// 罚款信息管理模块的API端点。
  static const String fineInformationEndpoint = '/eventbus/fines';

  /// 登录日志记录模块的API端点。
  static const String loginLoginEndpoint = '/eventbus/loginLogs';

  /// 违章信息管理模块的API端点。
  static const String offenseInformationEndpoint = '/eventbus/offenses';

  /// 操作日志记录模块的API端点。
  static const String operationLogEndpoint = '/eventbus/operationLogs';

  /// 权限管理模块的API端点。
  static const String permissionManagementEndpoint = '/eventbus/permissions';

  /// 角色管理模块的API端点。
  static const String roleManagementEndpoint = '/eventbus/roles';

  /// 系统日志管理模块的API端点。
  static const String systemLogsEndpoint = '/eventbus/systemLogs';

  /// 系统设置模块的API端点。
  static const String systemSettingsEndpoint = '/eventbus/systemSettings';

  /// 用户管理模块的API端点。
  static const String userManagementEndpoint = '/eventbus/users';

  /// 车辆信息管理模块的API端点。
  static const String vehicleInformationEndpoint = '/eventbus/vehicles';

  /// 违章详情管理模块的API端点。
  static const String offenseDetailsEndpoint = '/eventbus/offenseDetails';
}
