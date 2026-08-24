import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/core/config/app_config.dart';
import 'package:final_assignment_front/core/auth/user_profile_service.dart';
import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';

class AuthenticatedUser {
  const AuthenticatedUser({
    required this.username,
    required this.roles,
    this.userId,
  });

  final String username;
  final int? userId;
  final List<String> roles;

  bool hasRole(String role) {
    final normalizedRole = role.toUpperCase();
    return roles.any((value) {
      final normalized = value.toUpperCase();
      return normalized == normalizedRole ||
          normalized == 'ROLE_$normalizedRole';
    });
  }
}

/// Outcome of one refresh attempt against `POST /api/auth/refresh`.
///
/// `rejected` means the server explicitly refused the stored refresh token
/// (or none exists) — the session is unrecoverable and must be cleared.
/// `transientFailure` means the attempt failed without such a refusal —
/// the stored tokens may still be honored by the server, so they must be
/// preserved for a later attempt. The status sets are decided in
/// `_isTerminalRefreshRejection`.
enum SessionRefreshStatus { success, rejected, transientFailure }

class AuthService extends GetxService {
  AuthService({
    http.Client? client,
    this.refreshSkew = const Duration(minutes: 5),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration refreshSkew;
  bool _isRedirecting = false;
  Completer<SessionRefreshStatus>? _refreshCompleter;

  Future<bool> ensureValidSession({bool redirectIfInvalid = false}) async {
    final token = await AuthTokenStore.instance.getJwtToken();
    if (token == null || token.isEmpty) {
      if (redirectIfInvalid) {
        await redirectToLogin(clearStoredTokens: false);
      }
      return false;
    }

    try {
      final decodedToken = JwtDecoder.decode(token);
      if (!_shouldRefresh(token, decodedToken)) {
        return true;
      }

      final status = await refreshSession();
      if (status == SessionRefreshStatus.success) {
        final refreshedToken = await AuthTokenStore.instance.getJwtToken();
        if (refreshedToken != null && !JwtDecoder.isExpired(refreshedToken)) {
          return true;
        }
      } else if (status == SessionRefreshStatus.transientFailure) {
        if (!JwtDecoder.isExpired(token)) {
          // The access token is still valid; a throttled, failing, or
          // unreachable refresh endpoint must not destroy the session.
          // The next ensureValidSession call retries the refresh.
          return true;
        }
        // Hard-expired access token, but the refresh token was not rejected:
        // keep stored tokens so a later attempt can recover the session.
        if (redirectIfInvalid) {
          await redirectToLogin(clearStoredTokens: false);
        }
        return false;
      }

      await clearTokens();
      if (redirectIfInvalid) {
        await redirectToLogin(clearStoredTokens: false);
      }
      return false;
    } catch (error, stackTrace) {
      developer.log(
        'Invalid JWT token',
        error: error,
        stackTrace: stackTrace,
      );
      await clearTokens();
      if (redirectIfInvalid) {
        await redirectToLogin(clearStoredTokens: false);
      }
      return false;
    }
  }

  Future<String?> getValidJwtToken({bool redirectIfInvalid = false}) async {
    final isValid =
        await ensureValidSession(redirectIfInvalid: redirectIfInvalid);
    if (!isValid) return null;
    return AuthTokenStore.instance.getJwtToken();
  }

  Future<AuthenticatedUser?> currentUser({
    bool refreshIfNeeded = true,
    bool redirectIfInvalid = false,
  }) async {
    if (refreshIfNeeded) {
      final isValid =
          await ensureValidSession(redirectIfInvalid: redirectIfInvalid);
      if (!isValid) return null;
    }

    final token = await AuthTokenStore.instance.getJwtToken();
    if (token == null || token.isEmpty) return null;

    try {
      final decodedToken = JwtDecoder.decode(token);
      return AuthenticatedUser(
        username: decodedToken['sub']?.toString() ?? 'Unknown',
        userId: _intValue(decodedToken['userId']),
        roles: _extractRoles(decodedToken),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to decode current user from JWT',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<bool> refreshJwtToken() async =>
      await refreshSession() == SessionRefreshStatus.success;

  /// Single-flight refresh returning the classified outcome.
  Future<SessionRefreshStatus> refreshSession() async {
    final inFlight = _refreshCompleter;
    if (inFlight != null) {
      return inFlight.future;
    }

    final completer = Completer<SessionRefreshStatus>();
    _refreshCompleter = completer;
    try {
      final result = await _refreshJwtTokenInternal();
      completer.complete(result);
      return result;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Token refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (!completer.isCompleted) {
        completer.complete(SessionRefreshStatus.transientFailure);
      }
      return SessionRefreshStatus.transientFailure;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<SessionRefreshStatus> _refreshJwtTokenInternal() async {
    final refreshToken = await AuthTokenStore.instance.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      developer.log('No refresh token found');
      return SessionRefreshStatus.rejected;
    }

    try {
      final response = await _client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/auth/refresh'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        AppLogger.error('Refresh endpoint not found - may be using Cloud auth');
        await clearTokens();
        NavigationHelper.offAllNamed(Routes.login);
        return SessionRefreshStatus.rejected;
      }

      if (_isTerminalRefreshRejection(response.statusCode)) {
        developer.log('JWT refresh rejected: ${response.statusCode}');
        return SessionRefreshStatus.rejected;
      }

      if (response.statusCode != 200 || response.body.isEmpty) {
        developer.log('JWT refresh failed transiently: ${response.statusCode}');
        return SessionRefreshStatus.transientFailure;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['success'] == true && body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      final newJwt = (data['accessToken'] ?? data['jwtToken'])?.toString();
      if (newJwt == null || newJwt.isEmpty) {
        developer.log('JWT refresh response did not contain accessToken');
        return SessionRefreshStatus.transientFailure;
      }

      await AuthTokenStore.instance.setJwtToken(newJwt);
      final newRefreshToken = data['refreshToken']?.toString();
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await AuthTokenStore.instance.setRefreshToken(newRefreshToken);
      }
      developer.log('JWT token refreshed successfully');
      return SessionRefreshStatus.success;
    } catch (error, stackTrace) {
      developer.log(
        'Error refreshing JWT token',
        error: error,
        stackTrace: stackTrace,
      );
      return SessionRefreshStatus.transientFailure;
    }
  }

  /// The server refuses this refresh token: 400 (malformed request),
  /// 401 (invalid, rotated out, or revoked), 403 (forbidden). Everything
  /// else — 408/429/5xx, timeouts, network and parse errors — is transient
  /// and must not destroy stored tokens.
  bool _isTerminalRefreshRejection(int statusCode) {
    return statusCode == 400 || statusCode == 401 || statusCode == 403;
  }

  Future<void> handleForbidden({String? source, String? message}) async {
    developer.log(
      'Forbidden${source == null ? '' : ' from $source'}: ${message ?? 'access denied'}',
    );
  }

  Future<void> handleUnauthorized({String? source}) async {
    if (_isRedirecting || Get.currentRoute == Routes.login) {
      return;
    }

    developer.log(
      'Handling 401${source == null ? '' : ' from $source'}',
    );
    await redirectToLogin(clearStoredTokens: true);
  }

  Future<void> redirectToLogin({bool clearStoredTokens = true}) async {
    if (_isRedirecting || Get.currentRoute == Routes.login) {
      return;
    }

    _isRedirecting = true;
    if (clearStoredTokens) {
      await clearTokens();
    }

    for (var i = 0; i < 50; i++) {
      if (Get.context != null && Get.currentRoute != Routes.login) {
        NavigationHelper.offAllNamed(Routes.login);
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    _isRedirecting = false;
  }

  Future<void> clearTokens() async {
    await AuthTokenStore.instance.clearAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authUserId');
    await prefs.remove('auth_user_id');
    await prefs.remove('driverId');
    await prefs.remove('driver_id');
    await prefs.remove('userId');
    await prefs.remove('userRole');
    await prefs.remove('userName');
    await prefs.remove('username');
    await prefs.remove('roles');
    await prefs.remove('displayName');
    await prefs.remove('email');
    await prefs.remove('phoneNumber');
    await prefs.remove('driverName');
    await prefs.remove('userEmail');
    if (Get.isRegistered<UserProfileService>()) {
      Get.find<UserProfileService>().invalidate();
    }
  }

  Future<void> clearToken() => clearTokens();

  Future<void> logout() async {
    try {
      final token = await AuthTokenStore.instance.getJwtToken();
      if (token != null && token.isNotEmpty) {
        final response = await _client.post(
          Uri.parse('${AppConfig.apiBaseUrl}/api/auth/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 5));
        if (response.statusCode == 404) {
          AppLogger.error(
              'Logout endpoint not found - may be using Cloud auth');
        }
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Logout API failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      await clearTokens();
      NavigationHelper.offAllNamed(Routes.login);
    }
  }

  bool _shouldRefresh(String token, Map<String, dynamic> decodedToken) {
    if (JwtDecoder.isExpired(token)) {
      return true;
    }

    final expiresAt = _expirationDate(decodedToken);
    if (expiresAt == null) {
      return false;
    }

    return expiresAt.difference(DateTime.now()) <= refreshSkew;
  }

  DateTime? _expirationDate(Map<String, dynamic> decodedToken) {
    final exp = decodedToken['exp'];
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    }
    if (exp is num) {
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    }
    if (exp is String) {
      final value = int.tryParse(exp);
      if (value != null) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }
    return null;
  }

  int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  List<String> _extractRoles(Map<String, dynamic> decodedToken) {
    final roles = decodedToken['roles'] ?? decodedToken['authorities'];
    if (roles is List) {
      return roles.map((role) => role.toString()).toList(growable: false);
    }
    if (roles is String) {
      return roles
          .split(',')
          .map((role) => role.trim())
          .where((role) => role.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  @override
  void onClose() {
    _client.close();
    super.onClose();
  }
}
