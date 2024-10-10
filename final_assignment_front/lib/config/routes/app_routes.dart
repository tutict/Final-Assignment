part of 'app_pages.dart';

/// used to switch pages
class Routes {
  static const dashboard = _Paths.dashboard;
  static const login = _Paths.login;
  static const userDashboard = _Paths.userDashboard;
  static const aiChat = _Paths.aiChat;
  static const map = _Paths.map;
  static const onlineProcessingProgress = _Paths.onlineProcessingProgress;
  static const accountAndSecurity = _Paths.accountAndSecurity;
  static const changePassword = _Paths.changePassword;
  static const deleteAccount = _Paths.deleteAccount;
  static const informationStatement = _Paths.informationStatement;
  static const migrateAccount = _Paths.migrateAccount;
  static const changeMobilePhoneNumber = _Paths.changeMobilePhoneNumber;
  static const personalInfo = _Paths.personalInfo;
  static const setting = _Paths.setting;
  static const consultation = _Paths.consultation;
  static const personalMain = _Paths.personalMain;
  static const mainScan = _Paths.mainScan;
}
/// contains a list of route names.
// made separately to make it easier to manage route naming
class _Paths {
  static const dashboard = '/dashboard';
  static const login = '/login';
  static const aiChat = '/aiChat';
  static const map = '/map';
  static const userDashboard = '/userDashboard';
  static const onlineProcessingProgress = '/onlineProcessingProgress';
  static const accountAndSecurity = '/accountAndSecurity';
  static const changePassword = '/changePassword';
  static const deleteAccount = '/deleteAccount';
  static const informationStatement = '/informationStatement';
  static const migrateAccount = '/migrateAccount';
  static const changeMobilePhoneNumber = '/changeMobilePhoneNumber';
  static const personalInfo = '/personalInfo';
  static const setting = '/setting';
  static const consultation = '/consultation';
  static const personalMain = '/personalMain';
  static const mainScan = '/mainScan';

// Example :
// static const index = '/';
// static const splash = '/splash';
// static const product = '/product';
}
