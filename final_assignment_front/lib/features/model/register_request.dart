class RegisterRequest {
  final String username;
  final String password;
  final String role;
  final String? idempotencyKey;

  // 使用静态常量正则表达式，提高效率和可读性
  static final RegExp _domainRegExp = RegExp(r'@([^.]+)\.');

  /// 构造函数，根据 [username] 自动设置 [role]
  RegisterRequest({
    required this.username,
    required this.password,
    required this.idempotencyKey,
  }) : role = _determineRole(username);

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

  /// 根据 [username] 确定角色
  /// 如果域名是 'admin'，返回 'ADMIN'，否则返回 'USER'
  static String _determineRole(String username) {
    final match = _domainRegExp.firstMatch(username);
    if (match != null && match.groupCount >= 1) {
      final domain = match.group(1)?.toLowerCase();
      if (domain == 'admin') {
        return 'ADMIN';
      }
    }
    return 'USER';
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
