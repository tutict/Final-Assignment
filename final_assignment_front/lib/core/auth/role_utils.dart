import 'dart:convert';

class RoleUtils {
  const RoleUtils._();

  static List<String> parseRoles(Object? value) {
    if (value == null) return const [];
    if (value is List) {
      return _distinct(value
          .map((role) => _normalize(role.toString()))
          .where((role) => role.isNotEmpty));
    }

    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return const [];

    if (text.startsWith('[') && text.endsWith(']')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is List) return parseRoles(decoded);
      } catch (_) {
        final inner = text.substring(1, text.length - 1);
        return parseRoles(inner);
      }
    }

    return _distinct(text
        .split(',')
        .map((role) => _normalize(role))
        .where((role) => role.isNotEmpty));
  }

  static String preferredRole(Object? value) {
    final roles = parseRoles(value);
    if (roles.isEmpty) return 'USER';
    if (roles.any(_isSuperAdminCode)) return 'SUPER_ADMIN';
    if (roles.any(_isAdminCode)) return 'ADMIN';
    if (roles.any(_isAppealReviewerCode)) return 'APPEAL_REVIEWER';
    return roles.first;
  }

  static bool isAdminRole(Object? value) {
    final roles = parseRoles(value);
    return roles.any(_isAdminCode);
  }

  static bool isSuperAdminRole(Object? value) {
    final roles = parseRoles(value);
    return roles.any(_isSuperAdminCode);
  }

  static bool canAccessAdminDashboard(Object? value) {
    return isSuperAdminRole(value) || isAdminRole(value);
  }

  /// 管理端业务页面的准入角色：ADMIN 与 SUPER_ADMIN。
  ///
  /// 超管在权限上是 ADMIN 的超集：后端对罚款、扣分、违法、车辆等管理接口一律放行
  /// SUPER_ADMIN，管理端页面也把同一批入口展示给超管。用角色名的精确相等来判定
  /// 会把超管误判成"权限不足"，因此这里按集合语义判断。
  static bool canManageBusiness(Object? value) {
    final roles = parseRoles(value);
    return roles.any((role) => _isAdminCode(role) || _isSuperAdminCode(role));
  }

  static bool isAppealReviewerRole(Object? value) {
    return parseRoles(value).any(_isAppealReviewerCode);
  }

  static bool canAccessStaffDashboard(Object? value) {
    return canAccessAdminDashboard(value) || isAppealReviewerRole(value);
  }

  static bool _isAdminCode(String role) {
    return role == 'ADMIN';
  }

  static bool _isAppealReviewerCode(String role) {
    return role == 'APPEAL_REVIEWER';
  }

  static bool _isSuperAdminCode(String role) {
    return role == 'SUPER_ADMIN';
  }

  static String _normalize(String role) {
    final normalized =
        role.replaceAll('"', '').replaceAll("'", '').trim().toUpperCase();
    return normalized.startsWith('ROLE_')
        ? normalized.substring('ROLE_'.length)
        : normalized;
  }

  static List<String> _distinct(Iterable<String> roles) {
    final seen = <String>{};
    return [
      for (final role in roles)
        if (seen.add(role)) role,
    ];
  }
}
