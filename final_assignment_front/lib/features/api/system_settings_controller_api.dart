import 'package:final_assignment_front/features/model/system_settings.dart';
import 'package:final_assignment_front/features/model/sys_dict.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

/// å®ä¹ä¸ä¸ªå
// ¨å±ç?defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class SystemSettingsControllerApi {
  final ApiClient apiClient;

  /// æé å½æ°ï¼å¯ä¼ å
// ?ApiClientï¼å¦åä½¿ç¨å
// ¨å±é»è®¤å®ä¾
  SystemSettingsControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// ä»?SharedPreferences ä¸­è¯»å?jwtToken å¹¶è®¾ç½®å° ApiClient ä¸?
  Future<void> initializeWithJwt() async {
      final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw Exception('Not authenticated. Please log in again.');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized SystemSettingsControllerApi with token: $jwtToken');
  }

  String _decodeBodyBytes(Response response) {
    return response.body;
  }

  Future<Map<String, String>> _getHeaders({String? idempotencyKey}) async {
      final token = (await AuthTokenStore.instance.getJwtToken()) ?? '';
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (idempotencyKey != null && idempotencyKey.trim().isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey.trim();
    }
    return headers;
  }

  /// GET /api/systemSettings/copyrightInfo - è·åçæä¿¡æ¯
  Future<String?> apiSystemSettingsCopyrightInfoGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/copyrightInfo',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    return apiClient.deserialize(_decodeBodyBytes(response), 'String')
        as String?;
  }

  /// GET /api/systemSettings/dateFormat - è·åæ¥ææ ¼å¼
  Future<String?> apiSystemSettingsDateFormatGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/dateFormat',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    return apiClient.deserialize(_decodeBodyBytes(response), 'String')
        as String?;
  }

  /// GET /api/systemSettings/emailAccount - è·åé®ç®±è´¦æ·
  Future<String?> apiSystemSettingsEmailAccountGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/emailAccount',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    return apiClient.deserialize(_decodeBodyBytes(response), 'String')
        as String?;
  }

  /// GET /api/systemSettings/emailPassword - è·åé®ç®±å¯ç 
  Future<String?> apiSystemSettingsEmailPasswordGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/emailPassword',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    return apiClient.deserialize(_decodeBodyBytes(response), 'String')
        as String?;
  }

  /// GET /api/systemSettings - è·åææç³»ç»è®¾ç½?
  Future<SystemSettings?> apiSystemSettingsGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return SystemSettings.fromJson(data);
  }

  /// GET /api/systemSettings/loginTimeout - è·åç»å½è¶
// æ¶æ¶é´
  Future<int?> apiSystemSettingsLoginTimeoutGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/loginTimeout',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    return apiClient.deserialize(_decodeBodyBytes(response), 'int') as int?;
  }

  /// GET /api/systemSettings/pageSize - è·ååé¡µå¤§å°
  Future<int?> apiSystemSettingsPageSizeGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/pageSize',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    return apiClient.deserialize(_decodeBodyBytes(response), 'int') as int?;
  }

  /// PUT /api/systemSettings - æ´æ°ç³»ç»è®¾ç½® (ä»
// ç®¡çå)
  Future<SystemSettings> apiSystemSettingsPut(
      {required SystemSettings systemSettings}) async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings',
      'PUT',
      [],
      systemSettings.toJson(),
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return SystemSettings.fromJson(data);
  }

  /// GET /api/systemSettings/sessionTimeout - è·åä¼è¯è¶
// æ¶æ¶é´
  Future<int?> apiSystemSettingsSessionTimeoutGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/sessionTimeout',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    return apiClient.deserialize(_decodeBodyBytes(response), 'int') as int?;
  }

  /// GET /api/systemSettings/smtpServer - è·åSMTPæå¡å?
  Future<String?> apiSystemSettingsSmtpServerGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/smtpServer',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    return apiClient.deserialize(_decodeBodyBytes(response), 'String')
        as String?;
  }

  /// GET /api/systemSettings/storagePath - è·åå­å¨è·¯å¾
  Future<String?> apiSystemSettingsStoragePathGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/storagePath',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    return apiClient.deserialize(_decodeBodyBytes(response), 'String')
        as String?;
  }

  /// GET /api/systemSettings/systemDescription - è·åç³»ç»æè¿°
  Future<String?> apiSystemSettingsSystemDescriptionGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/systemDescription',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    return apiClient.deserialize(_decodeBodyBytes(response), 'String')
        as String?;
  }

  /// GET /api/systemSettings/systemName - è·åç³»ç»åç§°
  Future<String?> apiSystemSettingsSystemNameGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/systemName',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    return apiClient.deserialize(_decodeBodyBytes(response), 'String')
        as String?;
  }

  /// GET /api/systemSettings/systemVersion - è·åç³»ç»çæ¬
  Future<String?> apiSystemSettingsSystemVersionGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/systemVersion',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    return apiClient.deserialize(_decodeBodyBytes(response), 'String')
        as String?;
  }

  // --- New endpoints: /api/system/settings ---

  /// POST /api/system/settings
  Future<SystemSettings> apiSystemSettingsPost({
    required SystemSettings systemSettings,
    String? idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings',
      'POST',
      const [],
      systemSettings.toJson(),
      await _getHeaders(idempotencyKey: idempotencyKey),
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return SystemSettings.fromJson(data);
  }

  /// PUT /api/system/settings/{settingId}
  Future<SystemSettings> apiSystemSettingsSettingIdPut({
    required int settingId,
    required SystemSettings systemSettings,
    String? idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/$settingId',
      'PUT',
      const [],
      systemSettings.toJson(),
      await _getHeaders(idempotencyKey: idempotencyKey),
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return SystemSettings.fromJson(data);
  }

  /// DELETE /api/system/settings/{settingId}
  Future<void> apiSystemSettingsSettingIdDelete({
    required int settingId,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/$settingId',
      'DELETE',
      const [],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400 && response.statusCode != 204) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// GET /api/system/settings/{settingId}
  Future<SystemSettings?> apiSystemSettingsSettingIdGet({
    required int settingId,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/$settingId',
      'GET',
      const [],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return SystemSettings.fromJson(data);
  }

  /// GET /api/system/settings
  Future<List<SystemSettings>> apiSystemSettingsListGet() async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings',
      'GET',
      const [],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SystemSettings.listFromJson(data);
  }

  /// GET /api/system/settings/key/{settingKey}
  Future<SystemSettings?> apiSystemSettingsKeyGet({
    required String settingKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/key/$settingKey',
      'GET',
      const [],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return SystemSettings.fromJson(data);
  }

  /// GET /api/system/settings/category/{category}
  Future<List<SystemSettings>> apiSystemSettingsCategoryGet({
    required String category,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/category/$category',
      'GET',
      [
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SystemSettings.listFromJson(data);
  }

  /// GET /api/system/settings/search/key/prefix
  Future<List<SystemSettings>> apiSystemSettingsSearchKeyPrefixGet({
    required String settingKey,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/search/key/prefix',
      'GET',
      [
        QueryParam('settingKey', settingKey),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SystemSettings.listFromJson(data);
  }

  /// GET /api/system/settings/search/key/fuzzy
  Future<List<SystemSettings>> apiSystemSettingsSearchKeyFuzzyGet({
    required String settingKey,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/search/key/fuzzy',
      'GET',
      [
        QueryParam('settingKey', settingKey),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SystemSettings.listFromJson(data);
  }

  /// GET /api/system/settings/search/type
  Future<List<SystemSettings>> apiSystemSettingsSearchTypeGet({
    required String settingType,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/search/type',
      'GET',
      [
        QueryParam('settingType', settingType),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SystemSettings.listFromJson(data);
  }

  /// GET /api/system/settings/search/editable
  Future<List<SystemSettings>> apiSystemSettingsSearchEditableGet({
    required bool isEditable,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/search/editable',
      'GET',
      [
        QueryParam('isEditable', isEditable.toString()),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SystemSettings.listFromJson(data);
  }

  /// GET /api/system/settings/search/encrypted
  Future<List<SystemSettings>> apiSystemSettingsSearchEncryptedGet({
    required bool isEncrypted,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/search/encrypted',
      'GET',
      [
        QueryParam('isEncrypted', isEncrypted.toString()),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SystemSettings.listFromJson(data);
  }

  // --- Dict endpoints under /api/system/settings/dicts ---

  /// POST /api/system/settings/dicts
  Future<SysDictModel> apiSystemSettingsDictsPost({
    required SysDictModel sysDict,
    String? idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/dicts',
      'POST',
      const [],
      sysDict.toJson(),
      await _getHeaders(idempotencyKey: idempotencyKey),
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data =
        apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
    return SysDictModel.fromJson(data);
  }

  /// PUT /api/system/settings/dicts/{dictId}
  Future<SysDictModel> apiSystemSettingsDictsDictIdPut({
    required int dictId,
    required SysDictModel sysDict,
    String? idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/dicts/$dictId',
      'PUT',
      const [],
      sysDict.toJson(),
      await _getHeaders(idempotencyKey: idempotencyKey),
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data =
        apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
    return SysDictModel.fromJson(data);
  }

  /// DELETE /api/system/settings/dicts/{dictId}
  Future<void> apiSystemSettingsDictsDictIdDelete({
    required int dictId,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/dicts/$dictId',
      'DELETE',
      const [],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400 && response.statusCode != 204) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// GET /api/system/settings/dicts/{dictId}
  Future<SysDictModel?> apiSystemSettingsDictsDictIdGet({
    required int dictId,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/dicts/$dictId',
      'GET',
      const [],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    final data =
        apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
    return SysDictModel.fromJson(data);
  }

  /// GET /api/system/settings/dicts
  Future<List<SysDictModel>> apiSystemSettingsDictsGet() async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/dicts',
      'GET',
      const [],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SysDictModel.listFromJson(data);
  }

  /// GET /api/system/settings/dicts/search/type
  Future<List<SysDictModel>> apiSystemSettingsDictsSearchTypeGet({
    required String dictType,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/dicts/search/type',
      'GET',
      [
        QueryParam('dictType', dictType),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SysDictModel.listFromJson(data);
  }

  /// GET /api/system/settings/dicts/search/code
  Future<List<SysDictModel>> apiSystemSettingsDictsSearchCodeGet({
    required String dictCode,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/dicts/search/code',
      'GET',
      [
        QueryParam('dictCode', dictCode),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SysDictModel.listFromJson(data);
  }

  /// GET /api/system/settings/dicts/search/label/prefix
  Future<List<SysDictModel>> apiSystemSettingsDictsSearchLabelPrefixGet({
    required String dictLabel,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/dicts/search/label/prefix',
      'GET',
      [
        QueryParam('dictLabel', dictLabel),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SysDictModel.listFromJson(data);
  }

  /// GET /api/system/settings/dicts/search/label/fuzzy
  Future<List<SysDictModel>> apiSystemSettingsDictsSearchLabelFuzzyGet({
    required String dictLabel,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/dicts/search/label/fuzzy',
      'GET',
      [
        QueryParam('dictLabel', dictLabel),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SysDictModel.listFromJson(data);
  }

  /// GET /api/system/settings/dicts/search/parent
  Future<List<SysDictModel>> apiSystemSettingsDictsSearchParentGet({
    required int parentId,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/dicts/search/parent',
      'GET',
      [
        QueryParam('parentId', '$parentId'),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SysDictModel.listFromJson(data);
  }

  /// GET /api/system/settings/dicts/search/default
  Future<List<SysDictModel>> apiSystemSettingsDictsSearchDefaultGet({
    required bool isDefault,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/dicts/search/default',
      'GET',
      [
        QueryParam('isDefault', isDefault.toString()),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SysDictModel.listFromJson(data);
  }

  /// GET /api/system/settings/dicts/search/status
  Future<List<SysDictModel>> apiSystemSettingsDictsSearchStatusGet({
    required String status,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/settings/dicts/search/status',
      'GET',
      [
        QueryParam('status', status),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SysDictModel.listFromJson(data);
  }

  // WebSocket Methods (Aligned with HTTP Endpoints)

  /// GET /api/systemSettings/copyrightInfo (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="SystemSettingsService", action="getCopyrightInfo")
  Future<Object?> eventbusSystemSettingsCopyrightInfoGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getCopyrightInfo",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/systemSettings/dateFormat (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="SystemSettingsService", action="getDateFormat")
  Future<Object?> eventbusSystemSettingsDateFormatGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getDateFormat",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/systemSettings/emailAccount (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="SystemSettingsService", action="getEmailAccount")
  Future<Object?> eventbusSystemSettingsEmailAccountGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getEmailAccount",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/systemSettings/emailPassword (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="SystemSettingsService", action="getEmailPassword")
  Future<Object?> eventbusSystemSettingsEmailPasswordGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getEmailPassword",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/systemSettings (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="SystemSettingsService", action="getSystemSettings")
  Future<Object?> eventbusSystemSettingsGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getSystemSettings",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/systemSettings/loginTimeout (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="SystemSettingsService", action="getLoginTimeout")
  Future<Object?> eventbusSystemSettingsLoginTimeoutGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getLoginTimeout",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/systemSettings/pageSize (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="SystemSettingsService", action="getPageSize")
  Future<Object?> eventbusSystemSettingsPageSizeGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getPageSize",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// PUT /api/systemSettings (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="SystemSettingsService", action="updateSystemSettings")
  Future<Object?> eventbusSystemSettingsPut(
      {required SystemSettings systemSettings}) async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "updateSystemSettings",
      "args": [systemSettings.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/systemSettings/sessionTimeout (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="SystemSettingsService", action="getSessionTimeout")
  Future<Object?> eventbusSystemSettingsSessionTimeoutGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getSessionTimeout",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/systemSettings/smtpServer (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="SystemSettingsService", action="getSmtpServer")
  Future<Object?> eventbusSystemSettingsSmtpServerGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getSmtpServer",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/systemSettings/storagePath (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="SystemSettingsService", action="getStoragePath")
  Future<Object?> eventbusSystemSettingsStoragePathGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getStoragePath",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/systemSettings/systemDescription (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="SystemSettingsService", action="getSystemDescription")
  Future<Object?> eventbusSystemSettingsSystemDescriptionGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getSystemDescription",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/systemSettings/systemName (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="SystemSettingsService", action="getSystemName")
  Future<Object?> eventbusSystemSettingsSystemNameGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getSystemName",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/systemSettings/systemVersion (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="SystemSettingsService", action="getSystemVersion")
  Future<Object?> eventbusSystemSettingsSystemVersionGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getSystemVersion",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }
}
