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

  static bool _isAdminCode(String role) {
    return role == 'ADMIN';
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
