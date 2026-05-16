class RegisterRequest {
  final String username;
  final String password;
  final String role;
  final String? idempotencyKey;

  /// 公开注册固定为普通用户；管理员角色应由后台受保护接口分配。
  RegisterRequest({
    required this.username,
    required this.password,
    required this.idempotencyKey,
  }) : role = 'USER';

  /// 从 JSON 创建 [RegisterRequest] 实例
  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    final username = json['username'] as String?;
    final password = json['password'] as String?;
    final idempotencyKey = json['idempotencyKey'] as String?;

    // 验证必填字段是否存在
    if (username == null || password == null || idempotencyKey == null) {
      throw ArgumentError('Missing required fields in JSON');
    }

    return RegisterRequest(
      username: username,
      password: password,
      idempotencyKey: idempotencyKey,
    );
  }

  /// 将 [RegisterRequest] 实例转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'role': role,
      'idempotencyKey': idempotencyKey,
    };
  }

  @override
  String toString() {
    // 为了安全，隐藏密码字段
    return 'RegisterRequest[username=$username, password=******, role=$role, idempotencyKey=$idempotencyKey]';
  }

  /// 从 JSON 列表创建 [RegisterRequest] 列表
  static List<RegisterRequest> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((item) {
      if (item is Map<String, dynamic>) {
        return RegisterRequest.fromJson(item);
      } else {
        throw ArgumentError('Invalid item type in JSON list');
      }
    }).toList();
  }

  /// 从 JSON 映射创建 [RegisterRequest] 映射
  static Map<String, RegisterRequest> mapFromJson(
      Map<String, dynamic> jsonMap) {
    return jsonMap.map((key, value) {
      if (value is Map<String, dynamic>) {
        return MapEntry(key, RegisterRequest.fromJson(value));
      } else {
        throw ArgumentError('Invalid value type in JSON map');
      }
    });
  }

  /// 从包含 [RegisterRequest] 列表的 JSON 映射创建映射
  static Map<String, List<RegisterRequest>> mapListFromJson(
      Map<String, dynamic> jsonMap) {
    return jsonMap.map((key, value) {
      if (value is List<dynamic>) {
        return MapEntry(key, listFromJson(value));
      } else {
        throw ArgumentError('Invalid value type for key "$key" in JSON map');
      }
    });
  }
}
