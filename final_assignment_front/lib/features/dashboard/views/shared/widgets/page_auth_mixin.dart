import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/core/auth/auth_service.dart';
import 'package:final_assignment_front/core/auth/role_utils.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// Shared authentication and role-checking logic for dashboard pages.
///
/// Pages mix this in to avoid copying the JWT fetch → expiry → refresh →
/// role-decode boilerplate. The mixin never touches `setState` directly;
/// each page decides how to surface the failure (typically by setting its
/// `_errorMessage` and navigating away). Call [ensureFreshJwt] from a page
/// `State`'s init/fetch path; it returns the decoded token claims when the
/// caller may proceed, or `null` (after redirecting to login) when the
/// session is unrecoverable.
mixin PageAuthMixin<T extends StatefulWidget> on State<T> {
  /// Validates that a JWT exists and is fresh, refreshing it once when
  /// expired. Returns the decoded token claims on success.
  ///
  /// On an unrecoverable session the caller is redirected to the login
  /// route and `null` is returned; the page should `return` early.
  Future<Map<String, dynamic>?> ensureFreshJwt() async {
    String? jwtToken = await AuthTokenStore.instance.getJwtToken();
    if (jwtToken == null || jwtToken.isEmpty) {
      NavigationHelper.offAllNamed(Routes.login);
      return null;
    }
    try {
      var decoded = JwtDecoder.decode(jwtToken);
      if (JwtDecoder.isExpired(jwtToken)) {
        final refreshed = await Get.find<AuthService>().refreshJwtToken();
        jwtToken = await AuthTokenStore.instance.getJwtToken();
        if (!refreshed ||
            jwtToken == null ||
            jwtToken.isEmpty ||
            JwtDecoder.isExpired(jwtToken)) {
          NavigationHelper.offAllNamed(Routes.login);
          return null;
        }
        decoded = JwtDecoder.decode(jwtToken);
      }
      return decoded;
    } catch (_) {
      NavigationHelper.offAllNamed(Routes.login);
      return null;
    }
  }

  /// Convenience: validate the JWT then require [test] to pass on the
  /// caller's roles. Returns the roles when allowed, otherwise `null`
  /// (after redirecting when the session itself is gone).
  Future<List<String>?> requireRoles(
    bool Function(List<String> roles) test,
  ) async {
    final claims = await ensureFreshJwt();
    if (claims == null) return null;
    final roles = RoleUtils.parseRoles(claims['roles']);
    if (!test(roles)) return const [];
    return roles;
  }

  /// True when the current session's roles satisfy [RoleUtils.isAdminRole].
  Future<bool> currentIsAdmin() async {
    final claims = await ensureFreshJwt();
    if (claims == null) return false;
    return RoleUtils.isAdminRole(claims['roles']);
  }
}

/// Builds a redirect-friendly status surface for pages whose auth gate has
/// failed. Pages keep their own `_errorMessage` string; this helper turns a
/// caught error into a message consistent with the dashboard style.
String authErrorMessage(Object error) {
  if (error is AppException) {
    return switch (error.type) {
      AppErrorType.unauthorized => '登录已失效，请重新登录',
      AppErrorType.forbidden => '权限不足，无法访问该页面',
      _ => error.message,
    };
  }
  final text = error.toString();
  return text.startsWith('Exception: ') ? text.substring(11) : text;
}
