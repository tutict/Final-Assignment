import 'dart:convert';

import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/core/auth/role_utils.dart';
import 'package:final_assignment_front/features/model/chat_action.dart';
import 'package:final_assignment_front/features/model/chat_action_response.dart';

class BusinessChatAgent {
  const BusinessChatAgent();

  ChatActionResponse? resolve({
    required String message,
    required String role,
  }) {
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final prefill = _extractPrefill(message);
    if (RoleUtils.isSuperAdminRole(role)) {
      return _resolveSuperAdmin(normalized, prefill) ??
          _resolveAdmin(normalized, prefill);
    }
    if (RoleUtils.isAdminRole(role)) {
      return _resolveAdmin(normalized, prefill);
    }
    return _resolveDriver(normalized, prefill);
  }

  ChatActionResponse? _resolveDriver(
    String message,
    Map<String, String> prefill,
  ) {
    if (_containsAny(message, const ['申诉', '异议', '复议', '撤销处罚'])) {
      return _single(
        answer: '可以进入用户申诉页面，我会把识别到的车牌或违法编号作为预填线索带过去。',
        label: '打开用户申诉',
        route: Routes.userAppeal,
        prefill: prefill,
      );
    }
    if (_containsAny(message, const ['罚款', '缴费', '缴款', '缴纳', '支付'])) {
      return _single(
        answer: '可以进入罚款缴纳页面，查看待缴记录并继续支付流程。',
        label: '打开罚款缴纳',
        route: Routes.fineInformation,
        prefill: prefill,
      );
    }
    if (_containsAny(message, const ['违法', '违章', '扣分', '记分', '处罚'])) {
      return _single(
        answer: '可以进入违法详情页面，查看个人违法记录、处理状态和关联车辆信息。',
        label: '查看违法详情',
        route: Routes.userOffenseListPage,
        prefill: prefill,
      );
    }
    if (_containsAny(message, const ['车辆', '车牌', '登记', '绑定', '行驶证'])) {
      return _single(
        answer: '可以进入车辆登记管理页面，维护车辆档案和绑定信息。',
        label: '打开车辆登记',
        route: Routes.vehicleManagement,
        prefill: prefill,
      );
    }
    if (_containsAny(message, const ['进度', '消息', '办理状态', '处理结果'])) {
      return _single(
        answer: '可以进入进度消息页面，查看申诉、缴费或业务办理状态。',
        label: '查看进度消息',
        route: Routes.onlineProcessingProgress,
        prefill: prefill,
      );
    }
    if (_containsAny(message, const ['资料', '个人信息', '身份证', '驾驶证', '手机号'])) {
      return _single(
        answer: '可以进入个人资料页面，维护身份信息、驾驶证信息和联系方式。',
        label: '打开个人资料',
        route: Routes.personalMain,
        prefill: prefill,
      );
    }
    if (_containsAny(message, const ['地图', '位置', '附近', '导航'])) {
      return _single(
        answer: '可以打开地图模块查看位置相关信息。',
        label: '打开地图',
        route: Routes.map,
        prefill: prefill,
      );
    }
    return null;
  }

  ChatActionResponse? _resolveAdmin(
    String message,
    Map<String, String> prefill,
  ) {
    if (_containsAny(message, const ['申诉', '审批', '审核', '复核'])) {
      return _single(
        answer: '可以进入申诉审批管理页面，处理用户提交的申诉材料和审核进度。',
        label: '打开申诉审批',
        route: Routes.appealManagement,
        prefill: prefill,
      );
    }
    if (_containsAny(message, const ['扣分', '记分'])) {
      return _single(
        answer: '可以进入扣分管理页面，核对违法扣分记录和处理状态。',
        label: '打开扣分管理',
        route: Routes.deductionManagement,
        prefill: prefill,
      );
    }
    if (_containsAny(message, const ['罚款', '缴费', '缴款', '缴纳'])) {
      return _single(
        answer: '可以进入罚款管理页面，维护罚款记录、缴款状态和处理人信息。',
        label: '打开罚款管理',
        route: Routes.fineList,
        prefill: prefill,
      );
    }
    if (_containsAny(message, const ['司机', '驾驶员', '驾驶证'])) {
      return _single(
        answer: '可以进入司机管理页面，查看驾驶员档案及关联车辆、违法、罚款和申诉统计。',
        label: '打开司机管理',
        route: Routes.driverList,
        prefill: prefill,
      );
    }
    if (_containsAny(message, const ['车辆', '车牌', '车架', '发动机'])) {
      return _single(
        answer: '可以进入车辆管理页面，查看车辆档案、驾驶员绑定和关联业务统计。',
        label: '打开车辆管理',
        route: Routes.vehicleList,
        prefill: prefill,
      );
    }
    if (_containsAny(message, const ['违法', '违章', '处罚', '违法行为'])) {
      return _single(
        answer: '可以进入违法行为管理页面，查看和维护违法记录。',
        label: '打开违法管理',
        route: Routes.offenseList,
        prefill: prefill,
      );
    }
    if (_containsAny(message, const ['进度', '消息', '处理状态', '办理状态'])) {
      return _single(
        answer: '可以进入进度管理页面，查看业务请求、幂等状态和处理结果。',
        label: '打开进度管理',
        route: Routes.progressManagement,
        prefill: prefill,
      );
    }
    return null;
  }

  ChatActionResponse? _resolveSuperAdmin(
    String message,
    Map<String, String> prefill,
  ) {
    if (_containsAny(message, const ['rag', '知识库', '知识', '资料录入', '向量'])) {
      return _single(
        answer: '可以进入 RAG 资料管理页面，维护知识资料和向量化任务。',
        label: '打开 RAG 管理',
        route: Routes.ragManagement,
        prefill: prefill,
      );
    }
    if (_containsAny(message, const ['日志', '审计', '操作记录', '登录记录'])) {
      return _single(
        answer: '可以进入日志管理页面，审查登录日志、操作日志和系统日志。',
        label: '打开日志管理',
        route: Routes.logManagement,
        prefill: prefill,
      );
    }
    if (_containsAny(message, const ['用户', '账号', '账户', '权限', '角色'])) {
      return _single(
        answer: '可以进入用户管理页面，维护账号状态、角色和权限。',
        label: '打开用户管理',
        route: Routes.userManagementPage,
        prefill: prefill,
      );
    }
    if (_containsAny(message, const ['系统治理', '治理', '异常链路', '运维'])) {
      return _single(
        answer: '可以进入系统治理页面，集中查看系统治理入口和异常链路线索。',
        label: '打开系统治理',
        route: Routes.systemGovernance,
        prefill: prefill,
      );
    }
    return null;
  }

  ChatActionResponse _single({
    required String answer,
    required String label,
    required String route,
    required Map<String, String> prefill,
  }) {
    return ChatActionResponse(
      answer: answer,
      actions: [
        ChatAction(
          type: 'NAVIGATE',
          label: label,
          target: route,
          value: jsonEncode({
            'agentPrefill': prefill,
            'source': 'ai_chat',
          }),
        ),
      ],
      needConfirm: false,
    );
  }

  Map<String, String> _extractPrefill(String message) {
    final prefill = <String, String>{};
    final plate = RegExp(
      r'[京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼][A-Z][A-Z0-9]{5,6}',
      caseSensitive: false,
    ).firstMatch(message);
    if (plate != null) {
      prefill['licensePlate'] = plate.group(0)!.toUpperCase();
    }

    final number = RegExp(
      r'(?:违法|违章|处罚|申诉|业务|编号|单号|记录)[：:\s#-]*([A-Za-z0-9]{5,})',
      caseSensitive: false,
    ).firstMatch(message);
    if (number != null) {
      prefill['businessNumber'] = number.group(1)!;
    }
    return prefill;
  }

  bool _containsAny(String message, List<String> keywords) {
    return keywords.any(message.contains);
  }
}
