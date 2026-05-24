import 'package:final_assignment_front/features/model/sys_dict.dart';
import 'package:final_assignment_front/features/model/system_settings.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

final ApiClient defaultApiClient = ApiClient();

class SystemSettingsControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  SystemSettingsControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<String?> getSystemSettingsCopyrightInfo() {
    return _getStringSetting('/api/systemSettings/copyrightInfo');
  }

  Future<String?> getSystemSettingsDateFormat() {
    return _getStringSetting('/api/systemSettings/dateFormat');
  }

  Future<String?> getSystemSettingsEmailAccount() {
    return _getStringSetting('/api/systemSettings/emailAccount');
  }

  Future<String?> getSystemSettingsEmailPassword() {
    return _getStringSetting('/api/systemSettings/emailPassword');
  }

  Future<SystemSettings?> getSystemSettings() {
    return requestNullableObject(
      'GET',
      '/api/systemSettings',
      SystemSettings.fromJson,
      nullStatusCodes: const {404},
    );
  }

  Future<int?> getSystemSettingsLoginTimeout() {
    return _getIntSetting('/api/systemSettings/loginTimeout');
  }

  Future<int?> getSystemSettingsPageSize() {
    return _getIntSetting('/api/systemSettings/pageSize');
  }

  Future<SystemSettings> updateSystemSettings({
    required SystemSettings systemSettings,
  }) {
    return requestObject(
      'PUT',
      '/api/systemSettings',
      SystemSettings.fromJson,
      body: systemSettings.toJson(),
      contentType: BaseApiClient.defaultContentType,
    );
  }

  Future<int?> getSystemSettingsSessionTimeout() {
    return _getIntSetting('/api/systemSettings/sessionTimeout');
  }

  Future<String?> getSystemSettingsSmtpServer() {
    return _getStringSetting('/api/systemSettings/smtpServer');
  }

  Future<String?> getSystemSettingsStoragePath() {
    return _getStringSetting('/api/systemSettings/storagePath');
  }

  Future<String?> getSystemSettingsSystemDescription() {
    return _getStringSetting('/api/systemSettings/systemDescription');
  }

  Future<String?> getSystemSettingsSystemName() {
    return _getStringSetting('/api/systemSettings/systemName');
  }

  Future<String?> getSystemSettingsSystemVersion() {
    return _getStringSetting('/api/systemSettings/systemVersion');
  }

  Future<SystemSettings> createSystemSettings({
    required SystemSettings systemSettings,
    String? idempotencyKey,
  }) {
    return requestObject(
      'POST',
      '/api/system/settings',
      SystemSettings.fromJson,
      body: systemSettings.toJson(),
      contentType: BaseApiClient.defaultContentType,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<SystemSettings> updateSystemSetting({
    required int settingId,
    required SystemSettings systemSettings,
    String? idempotencyKey,
  }) {
    return requestObject(
      'PUT',
      '/api/system/settings/$settingId',
      SystemSettings.fromJson,
      body: systemSettings.toJson(),
      contentType: BaseApiClient.defaultContentType,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> deleteSystemSetting({required int settingId}) {
    return requestVoid('DELETE', '/api/system/settings/$settingId');
  }

  Future<SystemSettings?> getSystemSetting({required int settingId}) {
    return requestNullableObject(
      'GET',
      '/api/system/settings/$settingId',
      SystemSettings.fromJson,
    );
  }

  Future<List<SystemSettings>> listSystemSettings() {
    return requestList(
      'GET',
      '/api/system/settings',
      SystemSettings.fromJson,
    );
  }

  Future<SystemSettings?> getSystemSettingByKey({
    required String settingKey,
  }) {
    return requestNullableObject(
      'GET',
      '/api/system/settings/key/$settingKey',
      SystemSettings.fromJson,
    );
  }

  Future<List<SystemSettings>> listSystemSettingsByCategory({
    required String category,
    int page = 1,
    int size = 50,
  }) {
    return requestList(
      'GET',
      '/api/system/settings/category/$category',
      SystemSettings.fromJson,
      queryParams: pageParams(page, size),
    );
  }

  Future<List<SystemSettings>> searchSystemSettingsByKeyPrefix({
    required String settingKey,
    int page = 1,
    int size = 50,
  }) {
    return _searchSystemSettings(
      '/api/system/settings/search/key/prefix',
      {'settingKey': settingKey},
      page,
      size,
    );
  }

  Future<List<SystemSettings>> searchSystemSettingsByKeyFuzzy({
    required String settingKey,
    int page = 1,
    int size = 50,
  }) {
    return _searchSystemSettings(
      '/api/system/settings/search/key/fuzzy',
      {'settingKey': settingKey},
      page,
      size,
    );
  }

  Future<List<SystemSettings>> searchSystemSettingsByType({
    required String settingType,
    int page = 1,
    int size = 50,
  }) {
    return _searchSystemSettings(
      '/api/system/settings/search/type',
      {'settingType': settingType},
      page,
      size,
    );
  }

  Future<List<SystemSettings>> searchSystemSettingsByEditable({
    required bool isEditable,
    int page = 1,
    int size = 50,
  }) {
    return _searchSystemSettings(
      '/api/system/settings/search/editable',
      {'isEditable': isEditable},
      page,
      size,
    );
  }

  Future<List<SystemSettings>> searchSystemSettingsByEncrypted({
    required bool isEncrypted,
    int page = 1,
    int size = 50,
  }) {
    return _searchSystemSettings(
      '/api/system/settings/search/encrypted',
      {'isEncrypted': isEncrypted},
      page,
      size,
    );
  }

  Future<SysDictModel> createSystemSettingsDict({
    required SysDictModel sysDict,
    String? idempotencyKey,
  }) {
    return requestObject(
      'POST',
      '/api/system/settings/dicts',
      SysDictModel.fromJson,
      body: sysDict.toJson(),
      contentType: BaseApiClient.defaultContentType,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<SysDictModel> updateSystemSettingsDict({
    required int dictId,
    required SysDictModel sysDict,
    String? idempotencyKey,
  }) {
    return requestObject(
      'PUT',
      '/api/system/settings/dicts/$dictId',
      SysDictModel.fromJson,
      body: sysDict.toJson(),
      contentType: BaseApiClient.defaultContentType,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> deleteSystemSettingsDict({required int dictId}) {
    return requestVoid('DELETE', '/api/system/settings/dicts/$dictId');
  }

  Future<SysDictModel?> getSystemSettingsDict({required int dictId}) {
    return requestNullableObject(
      'GET',
      '/api/system/settings/dicts/$dictId',
      SysDictModel.fromJson,
    );
  }

  Future<List<SysDictModel>> listSystemSettingsDicts() {
    return requestList(
      'GET',
      '/api/system/settings/dicts',
      SysDictModel.fromJson,
    );
  }

  Future<List<SysDictModel>> searchSystemSettingsDictsByType({
    required String dictType,
    int page = 1,
    int size = 50,
  }) {
    return _searchDicts(
      '/api/system/settings/dicts/search/type',
      {'dictType': dictType},
      page,
      size,
    );
  }

  Future<List<SysDictModel>> searchSystemSettingsDictsByCode({
    required String dictCode,
    int page = 1,
    int size = 50,
  }) {
    return _searchDicts(
      '/api/system/settings/dicts/search/code',
      {'dictCode': dictCode},
      page,
      size,
    );
  }

  Future<List<SysDictModel>> searchSystemSettingsDictsByLabelPrefix({
    required String dictLabel,
    int page = 1,
    int size = 50,
  }) {
    return _searchDicts(
      '/api/system/settings/dicts/search/label/prefix',
      {'dictLabel': dictLabel},
      page,
      size,
    );
  }

  Future<List<SysDictModel>> searchSystemSettingsDictsByLabelFuzzy({
    required String dictLabel,
    int page = 1,
    int size = 50,
  }) {
    return _searchDicts(
      '/api/system/settings/dicts/search/label/fuzzy',
      {'dictLabel': dictLabel},
      page,
      size,
    );
  }

  Future<List<SysDictModel>> searchSystemSettingsDictsByParent({
    required int parentId,
    int page = 1,
    int size = 50,
  }) {
    return _searchDicts(
      '/api/system/settings/dicts/search/parent',
      {'parentId': parentId},
      page,
      size,
    );
  }

  Future<List<SysDictModel>> searchSystemSettingsDictsByDefault({
    required bool isDefault,
    int page = 1,
    int size = 50,
  }) {
    return _searchDicts(
      '/api/system/settings/dicts/search/default',
      {'isDefault': isDefault},
      page,
      size,
    );
  }

  Future<List<SysDictModel>> searchSystemSettingsDictsByStatus({
    required String status,
    int page = 1,
    int size = 50,
  }) {
    return _searchDicts(
      '/api/system/settings/dicts/search/status',
      {'status': status},
      page,
      size,
    );
  }

  Future<Object?> eventbusSystemSettingsCopyrightInfoGet() {
    return _getSettingEventbus('getCopyrightInfo');
  }

  Future<Object?> eventbusSystemSettingsDateFormatGet() {
    return _getSettingEventbus('getDateFormat');
  }

  Future<Object?> eventbusSystemSettingsEmailAccountGet() {
    return _getSettingEventbus('getEmailAccount');
  }

  Future<Object?> eventbusSystemSettingsEmailPasswordGet() {
    return _getSettingEventbus('getEmailPassword');
  }

  Future<Object?> eventbusSystemSettingsGet() {
    return _getSettingEventbus('getSystemSettings');
  }

  Future<Object?> eventbusSystemSettingsLoginTimeoutGet() {
    return _getSettingEventbus('getLoginTimeout');
  }

  Future<Object?> eventbusSystemSettingsPageSizeGet() {
    return _getSettingEventbus('getPageSize');
  }

  Future<Object?> eventbusSystemSettingsPut({
    required SystemSettings systemSettings,
  }) {
    return sendWs(
      service: 'SystemSettingsService',
      action: 'updateSystemSettings',
      args: [systemSettings.toJson()],
    );
  }

  Future<Object?> eventbusSystemSettingsSessionTimeoutGet() {
    return _getSettingEventbus('getSessionTimeout');
  }

  Future<Object?> eventbusSystemSettingsSmtpServerGet() {
    return _getSettingEventbus('getSmtpServer');
  }

  Future<Object?> eventbusSystemSettingsStoragePathGet() {
    return _getSettingEventbus('getStoragePath');
  }

  Future<Object?> eventbusSystemSettingsSystemDescriptionGet() {
    return _getSettingEventbus('getSystemDescription');
  }

  Future<Object?> eventbusSystemSettingsSystemNameGet() {
    return _getSettingEventbus('getSystemName');
  }

  Future<Object?> eventbusSystemSettingsSystemVersionGet() {
    return _getSettingEventbus('getSystemVersion');
  }

  Future<String?> _getStringSetting(String path) {
    return requestValue<String>('GET', path, 'String');
  }

  Future<int?> _getIntSetting(String path) {
    return requestValue<int>('GET', path, 'int');
  }

  Future<List<SystemSettings>> _searchSystemSettings(
    String path,
    Map<String, Object?> filters,
    int page,
    int size,
  ) {
    return requestList(
      'GET',
      path,
      SystemSettings.fromJson,
      queryParams: queryParamsFromMap({
        ...filters,
        'page': page,
        'size': size,
      }),
    );
  }

  Future<List<SysDictModel>> _searchDicts(
    String path,
    Map<String, Object?> filters,
    int page,
    int size,
  ) {
    return requestList(
      'GET',
      path,
      SysDictModel.fromJson,
      queryParams: queryParamsFromMap({
        ...filters,
        'page': page,
        'size': size,
      }),
    );
  }

  Future<Object?> _getSettingEventbus(String action) {
    return sendWs(
      service: 'SystemSettingsService',
      action: action,
    );
  }
}
