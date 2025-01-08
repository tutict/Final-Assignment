class SystemSettings {
  /* 系统名称，作为数据库主键字段映射 */
  String? systemName;

  /* 系统版本，映射到数据库system_version字段 */
  String? systemVersion;

  /* 系统描述，映射到数据库system_description字段 */
  String? systemDescription;

  /* 版权信息，映射到数据库copyright_info字段 */
  String? copyrightInfo;

  /* 存储路径，映射到数据库storage_path字段 */
  String? storagePath;

  /* 登录超时时间，映射到数据库login_timeout字段 */
  int? loginTimeout;

  /* 会话超时时间，映射到数据库session_timeout字段 */
  int? sessionTimeout;

  /* 日期格式，映射到数据库date_format字段 */
  String? dateFormat;

  /* 分页大小，映射到数据库page_size字段 */
  int? pageSize;

  /* SMTP服务器地址，映射到数据库smtp_server字段 */
  String? smtpServer;

  /* 邮箱账号，映射到数据库email_account字段 */
  String? emailAccount;

  /* 邮箱密码，映射到数据库email_password字段 */
  String? emailPassword;

  /* 备注信息，映射到数据库remarks字段 */
  String? remarks;

  String idempotencyKey;

  SystemSettings({
    required int? loginTimeout,
    required int? sessionTimeout,
    required String? dateFormat,
    required int? pageSize,
    required String? smtpServer,
    required String? emailAccount,
    required String? emailPassword,
    required String? remarks,
    required String idempotencyKey,
  });

  @override
  String toString() {
    return 'SystemSettings[systemName=$systemName, systemVersion=$systemVersion, systemDescription=$systemDescription, copyrightInfo=$copyrightInfo, storagePath=$storagePath, loginTimeout=$loginTimeout, sessionTimeout=$sessionTimeout, dateFormat=$dateFormat, pageSize=$pageSize, smtpServer=$smtpServer, emailAccount=$emailAccount, emailPassword=$emailPassword, remarks=$remarks, idempotencyKey=$idempotencyKey, ]';
  }

  SystemSettings.fromJson(Map<String, dynamic> json) {
    systemName = json['systemName'];
    systemVersion = json['systemVersion'];
    systemDescription = json['systemDescription'];
    copyrightInfo = json['copyrightInfo'];
    storagePath = json['storagePath'];
    loginTimeout = json['loginTimeout'];
    sessionTimeout = json['sessionTimeout'];
    dateFormat = json['dateFormat'];
    pageSize = json['pageSize'];
    smtpServer = json['smtpServer'];
    emailAccount = json['emailAccount'];
    emailPassword = json['emailPassword'];
    remarks = json['remarks'];
    idempotencyKey = json['idempotencyKey'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (systemName != null) {
      json['systemName'] = systemName;
    }
    if (systemVersion != null) {
      json['systemVersion'] = systemVersion;
    }
    if (systemDescription != null) {
      json['systemDescription'] = systemDescription;
    }
    if (copyrightInfo != null) {
      json['copyrightInfo'] = copyrightInfo;
    }
    if (storagePath != null) {
      json['storagePath'] = storagePath;
    }
    if (loginTimeout != null) {
      json['loginTimeout'] = loginTimeout;
    }
    if (sessionTimeout != null) {
      json['sessionTimeout'] = sessionTimeout;
    }
    if (dateFormat != null) {
      json['dateFormat'] = dateFormat;
    }
    if (pageSize != null) {
      json['pageSize'] = pageSize;
    }
    if (smtpServer != null) {
      json['smtpServer'] = smtpServer;
    }
    if (emailAccount != null) {
      json['emailAccount'] = emailAccount;
    }
    if (emailPassword != null) {
      json['emailPassword'] = emailPassword;
    }
    if (remarks != null) {
      json['remarks'] = remarks;
    }
    return json;
  }

  static List<SystemSettings> listFromJson(List<dynamic> json) {
    return json.map((value) => SystemSettings.fromJson(value)).toList();
  }

  static Map<String, SystemSettings> mapFromJson(Map<String, dynamic> json) {
    var map = <String, SystemSettings>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
          map[key] = SystemSettings.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of SystemSettings-objects as value to a dart map
  static Map<String, List<SystemSettings>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<SystemSettings>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = SystemSettings.listFromJson(value);
      });
    }
    return map;
  }
}
