import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/features/model/chat_action.dart';

/// 业务动作条目：动作按钮文案与目标路由的唯一来源。
class BusinessActionEntry {
  const BusinessActionEntry({required this.label, required this.route});

  final String label;
  final String route;

  ChatAction toAction({String? value}) {
    return ChatAction(
      type: 'NAVIGATE',
      label: label,
      target: route,
      value: value,
    );
  }
}

/// 业务动作目录：把后端 agent 与本地关键词代理的动作统一到同一套文案和路由。
class BusinessActionCatalog {
  const BusinessActionCatalog._();

  // 用户侧入口
  static const userAppeal =
      BusinessActionEntry(label: '打开用户申诉', route: RoutePaths.userAppeal);
  static const finePayment =
      BusinessActionEntry(label: '打开罚款缴纳', route: RoutePaths.fineInformation);
  static const offenseDetail = BusinessActionEntry(
      label: '查看违法详情', route: RoutePaths.userOffenseListPage);
  static const vehicleRegistration = BusinessActionEntry(
      label: '打开车辆登记', route: RoutePaths.vehicleManagement);
  static const progressMessages = BusinessActionEntry(
      label: '查看进度消息', route: RoutePaths.onlineProcessingProgress);
  static const personalProfile =
      BusinessActionEntry(label: '打开个人资料', route: RoutePaths.personalMain);
  static const mapPage =
      BusinessActionEntry(label: '打开地图', route: RoutePaths.map);

  // 管理侧入口
  static const ragManagement =
      BusinessActionEntry(label: '打开 RAG 管理', route: RoutePaths.ragManagement);
  static const appealApproval = BusinessActionEntry(
      label: '打开申诉审批', route: RoutePaths.appealManagement);
  static const deductionManagement = BusinessActionEntry(
      label: '打开扣分管理', route: RoutePaths.deductionManagement);
  static const fineManagement =
      BusinessActionEntry(label: '打开罚款管理', route: RoutePaths.fineList);
  static const driverManagement =
      BusinessActionEntry(label: '打开司机管理', route: RoutePaths.driverList);
  static const vehicleManagement = BusinessActionEntry(
      label: '打开车辆管理', route: RoutePaths.vehicleList);
  static const offenseManagement =
      BusinessActionEntry(label: '打开违法管理', route: RoutePaths.offenseList);
  static const progressManagement = BusinessActionEntry(
      label: '打开进度管理', route: RoutePaths.progressManagement);
  static const userManagement = BusinessActionEntry(
      label: '打开用户管理', route: RoutePaths.userManagementPage);
  static const logManagement =
      BusinessActionEntry(label: '打开日志管理', route: RoutePaths.logManagement);
  static const systemGovernance = BusinessActionEntry(
      label: '打开系统治理', route: RoutePaths.systemGovernance);
  static const backupAndRestore = BusinessActionEntry(
      label: '打开备份与恢复', route: RoutePaths.backupAndRestore);

  /// 把跳转目标解析成业务入口，未知目标返回 null。
  ///
  /// [isStaff] 决定同名目标在管理端与用户端分别对应哪个页面。
  static BusinessActionEntry? resolve(String? target, {required bool isStaff}) {
    final key = _normalize(target);
    if (key.isEmpty) return null;
    switch (key) {
      case 'appealmanagement':
      case 'admin/appealmanagement':
        return appealApproval;
      case 'userappeal':
        return userAppeal;
      case 'fineinformation':
        return isStaff ? fineManagement : finePayment;
      case 'finelist':
      case 'admin/finelist':
        return fineManagement;
      case 'deductioninformation':
      case 'deductionmanagement':
        return deductionManagement;
      case 'driverinformation':
      case 'driverlist':
        return driverManagement;
      case 'vehicleinformation':
        return isStaff ? vehicleManagement : vehicleRegistration;
      case 'vehiclenagement':
        return vehicleRegistration;
      case 'vehiclelist':
        return vehicleManagement;
      case 'offenselist':
        return offenseManagement;
      case 'useroffenselistpage':
        return offenseDetail;
      case 'personalmain':
        return personalProfile;
      case 'progressitem':
        return isStaff ? progressManagement : progressMessages;
      case 'progressmanagement':
        return progressManagement;
      case 'onlineprocessingprogress':
        return progressMessages;
      case 'usermanagement':
      case 'admin/usermanagementpage':
        return userManagement;
      case 'logmanagement':
      case 'admin/logmanagement':
        return logManagement;
      case 'admin/systemgovernance':
      case 'systemgovernance':
        return systemGovernance;
      case 'admin/backupandrestore':
      case 'backupandrestore':
        return backupAndRestore;
      case 'ragmanagement':
        return ragManagement;
      case 'map':
      case 'admin/map':
        return mapPage;
      default:
        return null;
    }
  }

  static String _normalize(String? target) {
    final trimmed = target?.trim().toLowerCase() ?? '';
    if (trimmed.isEmpty) return '';
    return trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  }
}
