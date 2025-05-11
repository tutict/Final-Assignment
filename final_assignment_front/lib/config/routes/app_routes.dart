part of 'app_pages.dart';

/// 用于切换页面
class Routes {
  /// 首页路由
  static const dashboard = _Paths.dashboard;

  /// 登录页面路由
  static const login = _Paths.login;

  /// 用户仪表盘页面路由
  static const userDashboard = _Paths.userDashboard;

  /// AI聊天页面路由
  static const aiChat = _Paths.aiChat;

  /// 地图页面路由
  static const map = _Paths.map;

  /// 在线处理进度页面路由
  static const onlineProcessingProgress = _Paths.onlineProcessingProgress;

  /// 账户与安全页面路由
  static const accountAndSecurity = _Paths.accountAndSecurity;

  /// 修改密码页面路由
  static const changePassword = _Paths.changePassword;

  /// 删除账户页面路由
  static const deleteAccount = _Paths.deleteAccount;

  /// 信息声明页面路由
  static const informationStatement = _Paths.informationStatement;

  /// 账户迁移页面路由
  static const migrateAccount = _Paths.migrateAccount;

  /// 修改手机号码页面路由
  static const changeMobilePhoneNumber = _Paths.changeMobilePhoneNumber;

  /// 个人信息页面路由
  static const personalInfo = _Paths.personalInfo;

  /// 设置页面路由
  static const userSetting = _Paths.userSetting;

  /// 咨询页面路由
  static const consultation = _Paths.consultation;

  /// 个人主页页面路由
  static const personalMain = _Paths.personalMain;

  /// 主扫描页面路由
  static const mainScan = _Paths.mainScan;

  /// 新闻详情页面路由
  static const newsDetailScreen = _Paths.newsDetailScreen;

  // 申诉管理页面路由
  static const appealManagement = _Paths.appealManagement;

  // 备份与恢复页面路由
  static const backupAndRestore = _Paths.backupAndRestore;

  // 驾驶证列表页面路由
  static const driverList = _Paths.driverList;

  // 罚款列表页面路由
  static const fineList = _Paths.fineList;

  // 管理员个人主页页面路由
  static const managerPersonalPage = _Paths.managerPersonalPage;

  // 管理员设置页面路由
  static const managerSetting = _Paths.managerSetting;

  // 违章列表页面路由
  static const offenseList = _Paths.offenseList;

  // 车辆列表页面路由
  static const vehicleList = _Paths.vehicleList;

  // 罚款信息页面路由
  static const fineInformation = _Paths.fineInformation;

  // 用户申诉页面路由
  static const userAppeal = _Paths.userAppeal;

  // 在线处理页面路由
  static const onlineProcessing = _Paths.onlineProcessing;

  // 车辆详情页面路由
  static const vehicleManagement = _Paths.vehicleManagement;

  // 切换主题
  static const changeThemes = _Paths.changeThemes;

  // 用户业务办理页面
  static const businessProgress = _Paths.businessProgress;

  // 管理员用户业务处理页面
  static const managerBusinessProcessing = _Paths.managerBusinessProcessing;

  // 事故现场证据介绍页路由
  static const accidentEvidencePage = _Paths.accidentEvidencePage;

  // 事故现场证据介绍页路由
  static const accidentProgressPage = _Paths.accidentProgressPage;

  // 事故现场快速处理介绍页路由
  static const accidentQuickGuidePage = _Paths.accidentQuickGuidePage;

  // 事故现场处理视频介绍页路由
  static const accidentVideoQuickPage = _Paths.accidentVideoQuickPage;

  // 罚款支付介绍页路由
  static const finePaymentNoticePage = _Paths.finePaymentNoticePage;

  // 最新交通违章新闻介绍路由
  static const latestTrafficViolationNewsPage =
      _Paths.latestTrafficViolationNewsPage;

  // 管理员管理进度页面
  static const progressManagement = _Paths.progressManagement;

  // 进度详情页面路由
  static const progressDetailPage = _Paths.progressDetailPage;

  // 日志管理页面路由
  static const logManagement = _Paths.logManagement;

  // 用户管理页面路由
  static const userManagementPage = _Paths.userManagementPage;

  // 登录日志页面路由
  static const loginLogPage = _Paths.loginLogPage;

  // 操作日志页面路由
  static const operationLogPage = _Paths.operationLogPage;

  // 系统日志页面路由
  static const systemLogPage = _Paths.systemLogPage;

  // 用户违章列表页面路由
  static const userOffenseListPage = _Paths.userOffenseListPage;

  // 违章列表页面路由
  static const trafficViolationScreen = _Paths.trafficViolationScreen;

  static const progressManagementPage  = _Paths.progressManagementPage;
}

/// 包含路由名称列表。
/// 单独创建以方便管理路由命名。
class _Paths {
  /// 首页路由
  static const dashboard = '/dashboard';

  /// 登录路由
  static const login = '/login';

  /// AI聊天路由
  static const aiChat = '/aiChat';

  // /// 地图路由
  static const map = '/map';

  /// 用户仪表盘路由
  static const userDashboard = '/userDashboard';

  /// 在线处理进度路由
  static const onlineProcessingProgress = '/onlineProcessingProgress';

  /// 账户与安全路由
  static const accountAndSecurity = '/accountAndSecurity';

  /// 修改密码路由
  static const changePassword = '/changePassword';

  /// 删除账户路由
  static const deleteAccount = '/deleteAccount';

  /// 信息声明路由
  static const informationStatement = '/informationStatement';

  /// 账户迁移路由
  static const migrateAccount = '/migrateAccount';

  /// 修改手机号码路由
  static const changeMobilePhoneNumber = '/changeMobilePhoneNumber';

  /// 个人信息路由
  static const personalInfo = '/personalInfo';

  /// 用户设置路由
  static const userSetting = '/userSetting';

  /// 管理员设置路由
  static const managerSetting = '/managerSetting';

  /// 咨询路由
  static const consultation = '/consultation';

  /// 个人主页路由
  static const personalMain = '/personalMain';

  /// 主扫描路由
  static const mainScan = '/mainScan';

  /// 新闻详情路由
  static const newsDetailScreen = '/newsDetailScreen';

  // 申诉管理路由
  static const appealManagement = '/appealManagement';

  // 备份与恢复路由
  static const backupAndRestore = '/backupAndRestore';

  // 驾驶证列表路由
  static const driverList = '/driverList';

  // 罚款列表路由
  static const fineList = '/fineList';

  // 管理员个人主页路由
  static const managerPersonalPage = '/managerPersonalPage';

  // 违章列表路由
  static const offenseList = '/offenseList';

  // 车辆列表路由
  static const vehicleList = '/vehicleList';

  // 罚款信息路由
  static const fineInformation = '/fineInformation';

  // 在线处理路由
  static const onlineProcessing = '/onlineProcessing';

  // 用户申诉路由
  static const userAppeal = '/userAppeal';

  // 车辆详情路由
  static const vehicleManagement = '/vehicleManagement';

  // 切换主题
  static const changeThemes = '/changeThemes';

  // 用户业务办理页面
  static const businessProgress = '/businessProgress';

  // 管理员用户业务处理页面
  static const managerBusinessProcessing = '/managerBusinessProcessing';

  // 事故现场证据介绍页路由
  static const accidentEvidencePage = '/accidentEvidencePage';

  // 事故现场处理介绍页路由
  static const accidentProgressPage = '/accidentProgressPage';

  // 事故现场快速处理介绍页路由
  static const accidentQuickGuidePage = '/accidentQuickGuidePage';

  // 事故现场处理视频介绍页路由
  static const accidentVideoQuickPage = '/accidentVideoQuickPage';

  // 罚款支付介绍页路由
  static const finePaymentNoticePage = '/finePaymentNoticePage';

  // 最新交通违章新闻路由
  static const latestTrafficViolationNewsPage =
      '/latestTrafficViolationNewsPage';

  // 管理员进度管理页面
  static const progressManagement = '/progressManagement';

  // 进度详情页面
  static const progressDetailPage = '/progressDetailPage';

  //  日志管理页面路由
  static const logManagement = '/logManagement';

  // 用户管理页面路由
  static const userManagementPage = '/userManagementPage';

  // 登录日志页面路由
  static const loginLogPage = '/loginLogPage';

  // 操作日志页面路由
  static const operationLogPage = '/operationLogPage';

  // 系统日志页面
  static const systemLogPage = '/systemLogPage';

  // 用户处罚列表页面路由
  static const userOffenseListPage = '/userOffenseListPage';

  // 违章列表页面路由
  static const trafficViolationScreen = '/trafficViolationScreen';

  static const progressManagementPage = '/progressManagementPage';
// 示例：
// static const index = '/';
// static const splash = '/splash';
// static const product = '/product';
}
