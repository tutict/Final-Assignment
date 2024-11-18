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
  // static const map = _Paths.map;

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
  static const setting = _Paths.setting;

  /// 咨询页面路由
  static const consultation = _Paths.consultation;

  /// 个人主页页面路由
  static const personalMain = _Paths.personalMain;

  /// 主扫描页面路由
  static const mainScan = _Paths.mainScan;

  /// 新闻详情页面路由
  static const newsDetailScreen = _Paths.newsDetailScreen;
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

  /// 地图路由
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

  /// 设置路由
  static const setting = '/setting';

  /// 咨询路由
  static const consultation = '/consultation';

  /// 个人主页路由
  static const personalMain = '/personalMain';

  /// 主扫描路由
  static const mainScan = '/mainScan';

  /// 新闻详情路由
  static const newsDetailScreen = '/newsDetailScreen';
// 示例：
// static const index = '/';
// static const splash = '/splash';
// static const product = '/product';
}
