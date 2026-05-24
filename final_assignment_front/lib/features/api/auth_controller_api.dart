import 'dart:convert';

import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/features/model/login_request.dart';
import 'package:final_assignment_front/features/model/register_request.dart';
import 'package:final_assignment_front/features/model/user_response.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

final ApiClient defaultApiClient = ApiClient();

class AuthControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  AuthControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<Map<String, dynamic>> login({
    required LoginRequest loginRequest,
  }) async {
    final response = await request(
      'POST',
      '/api/auth/login',
      body: loginRequest,
      headers: _publicHeaders,
      contentType: BaseApiClient.defaultContentType,
      includeAuthHeader: false,
      authNames: const [],
    );
    final body = decodeBodyBytes(response).trim();
    return body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
  }

  Future<Map<String, dynamic>> register({
    required RegisterRequest registerRequest,
  }) async {
    final response = await request(
      'POST',
      '/api/auth/register',
      body: registerRequest,
      headers: _publicHeaders,
      contentType: BaseApiClient.defaultContentType,
      includeAuthHeader: false,
      authNames: const [],
    );
    final body = decodeBodyBytes(response).trim();
    if (body.isNotEmpty) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    if (response.statusCode == 201) {
      return {'status': 'CREATED'};
    }
    throw AppException.http(response.statusCode, 'Empty response body');
  }

  Future<List<UserResponse>> listAuthUsers() {
    return requestList('GET', '/api/auth/users', UserResponse.fromJson);
  }

  Future<Map<String, dynamic>> listRoles() async {
    final response = await request('GET', '/api/roles');
    final body = decodeBodyBytes(response).trim();
    if (body.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
  }

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final response = await request(
      'GET',
      '/api/auth/me',
      passThroughStatusCodes: const {404},
    );
    if (response.statusCode == 404) {
      return null;
    }
    if (decodeBodyBytes(response).trim().isEmpty) {
      return <String, dynamic>{};
    }
    return parseMapResponse(response);
  }

  Future<void> updateCurrentPassword({
    required String newPassword,
    required String idempotencyKey,
  }) {
    requireNotBlank(newPassword, 'newPassword');
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return requestVoid(
      'PUT',
      '/api/users/me/password',
      body: newPassword,
      contentType: 'text/plain; charset=utf-8',
      idempotencyKey: idempotencyKey,
      successStatusCodes: const {200, 204},
    );
  }

  Future<Object?> eventbusAuthLoginPost({
    required LoginRequest loginRequest,
  }) {
    return sendWs(
      service: 'AuthWsService',
      action: 'login',
      args: [
        {
          'username': loginRequest.username,
          'password': loginRequest.password,
        },
      ],
    );
  }

  Future<Object?> eventbusAuthRegisterPost({
    required RegisterRequest registerRequest,
  }) {
    return sendWs(
      service: 'AuthWsService',
      action: 'registerUser',
      args: [
        {
          'username': registerRequest.username,
          'password': registerRequest.password,
          'role': registerRequest.role,
          'idempotencyKey': registerRequest.idempotencyKey,
        },
      ],
    );
  }

  Future<Object?> eventbusAuthUsersGet() {
    return sendWs(
      service: 'AuthWsService',
      action: 'getAllUsers',
    );
  }

  static const _publicHeaders = {
    'Accept': 'application/json',
  };
}
