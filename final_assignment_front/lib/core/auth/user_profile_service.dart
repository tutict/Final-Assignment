import 'dart:convert';

import 'package:final_assignment_front/core/auth/user_profile.dart';
import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService extends GetxService {
  UserProfileService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  static const _profileCacheVersion = '2';

  final ApiClient _apiClient;
  UserProfile? _cachedProfile;

  Future<UserProfile> getProfile() async {
    if (_cachedProfile != null) return _cachedProfile!;

    final storedProfile = await _loadFromStorage(requireFreshCache: true);
    if (storedProfile != null) {
      _cachedProfile = storedProfile;
      return storedProfile;
    }

    return _fetchFromServer();
  }

  Future<String?> get driverId async =>
      (await getProfile()).driverId?.toString();

  Future<String> get authUserId async =>
      (await getProfile()).authUserId.toString();

  void invalidate() => _cachedProfile = null;

  Future<void> persistFromLoginResponse(Map<String, dynamic> result) async {
    final data = _unwrapPayload(result);

    final userData = data['user'];
    final authUserId = data['authUserId'] ??
        data['userId'] ??
        (userData is Map ? userData['authUserId'] ?? userData['userId'] : null);
    if (authUserId == null) {
      invalidate();
      return;
    }

    final profile = UserProfile.fromJson({
      'authUserId': authUserId,
      'username':
          data['username'] ?? (userData is Map ? userData['username'] : null),
      'displayName': data['displayName'],
      'email': data['email'],
      'phoneNumber': data['phoneNumber'],
      'roles': data['roleCodes'] ?? data['roles'],
      'driverId':
          data['driverId'] ?? (userData is Map ? userData['driverId'] : null),
      'driverName': data['driverName'],
    });

    _cachedProfile = profile;
    await _persist(profile);
  }

  Future<UserProfile> _fetchFromServer() async {
    final response = await _apiClient.invokeAPI(
      '/api/auth/me',
      'GET',
      const [],
      null,
      const {},
      const {},
      null,
      const ['bearerAuth'],
    );

    if (response.statusCode == 404) {
      AppLogger.error('Profile endpoint not found - may be using Cloud auth');
      await AuthTokenStore.instance.clearJwtToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('refreshToken');
      await prefs.remove('refresh_token');
      invalidate();
      NavigationHelper.offAllNamed(Routes.login);
      throw StateError('Profile endpoint not found');
    }

    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    final data = _unwrapPayload(body);

    _cachedProfile = UserProfile.fromJson(data);
    await _persist(_cachedProfile!);
    return _cachedProfile!;
  }

  Future<UserProfile?> _loadFromStorage(
      {required bool requireFreshCache}) async {
    final prefs = await SharedPreferences.getInstance();
    if (requireFreshCache &&
        prefs.getString('user_profile_cache_version') != _profileCacheVersion) {
      return null;
    }

    final values = {
      'auth_user_id': prefs.getString('auth_user_id'),
      'authUserId': prefs.getString('authUserId'),
      'userId': prefs.getString('userId'),
      'username': prefs.getString('username'),
      'userName': prefs.getString('userName'),
      'displayName': prefs.getString('displayName'),
      'email': prefs.getString('email'),
      'userEmail': prefs.getString('userEmail'),
      'phoneNumber': prefs.getString('phoneNumber'),
      'roles': prefs.getString('roles'),
      'userRole': prefs.getString('userRole'),
      'driver_id': prefs.getString('driver_id'),
      'driverId': prefs.getString('driverId'),
      'driverName': prefs.getString('driverName'),
    };

    if ((values['auth_user_id'] ?? values['authUserId'] ?? values['userId']) ==
        null) {
      return null;
    }

    try {
      return UserProfile.fromStorage(values);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load user profile from storage',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> _persist(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final authUserId = profile.authUserId.toString();
    await prefs.setString('user_profile_cache_version', _profileCacheVersion);
    await prefs.setString('auth_user_id', authUserId);
    await prefs.setString('authUserId', authUserId);
    await prefs.setString('userId', authUserId);
    await prefs.setString('username', profile.username);
    await prefs.setString('userName', profile.username);
    await prefs.setString('roles', jsonEncode(profile.roles));

    if (profile.roles.isNotEmpty) {
      await prefs.setString('userRole', profile.roles.first);
    }
    if (profile.displayName != null) {
      await prefs.setString('displayName', profile.displayName!);
    } else {
      await prefs.remove('displayName');
    }
    if (profile.email != null) {
      await prefs.setString('email', profile.email!);
      await prefs.setString('userEmail', profile.email!);
    } else {
      await prefs.remove('email');
      await prefs.remove('userEmail');
    }
    if (profile.phoneNumber != null) {
      await prefs.setString('phoneNumber', profile.phoneNumber!);
    } else {
      await prefs.remove('phoneNumber');
    }
    if (profile.driverId != null) {
      final driverId = profile.driverId.toString();
      await prefs.setString('driver_id', driverId);
      await prefs.setString('driverId', driverId);
    } else {
      await prefs.remove('driver_id');
      await prefs.remove('driverId');
    }
    if (profile.driverName != null) {
      await prefs.setString('driverName', profile.driverName!);
    } else {
      await prefs.remove('driverName');
    }
  }

  Map<String, dynamic> _unwrapPayload(Map<String, dynamic> body) {
    final payload = body['success'] == true && body['data'] is Map
        ? body['data'] as Map
        : body;
    return Map<String, dynamic>.from(payload);
  }
}
