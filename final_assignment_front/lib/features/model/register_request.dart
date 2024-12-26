class RegisterRequest {
  final String username;
  final String password;
  final String role;

  // 定义正则表达式为静态常量，避免每次实例化时重新编译
  static final RegExp _regExp = RegExp(r'@([^.]+)\.');

  // 构造函数中根据用户名设置角色
  RegisterRequest({
    required this.username,
    required this.password,
  }) : role = _determineRole(username);

  // 从 JSON 创建 RegisterRequest 实例时设置角色
  RegisterRequest.fromJson(Map<String, dynamic> json)
      : username = json['username'],
        password = json['password'],
        role = _determineRole(json['username']);

  // 将 RegisterRequest 实例转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'role': role,
    };
  }

  @override
  String toString() {
    return 'RegisterRequest[username=$username, password=$password, role=$role]';
  }

  // 通过正则表达式确定角色
  static String _determineRole(String username) {
    // 假设 username 是类似 '123@admin.com' 的邮箱地址
    final match = _regExp.firstMatch(username);
    if (match != null && match.groupCount >= 1) {
      final domain = match.group(1)?.toLowerCase();
      if (domain == 'admin') {
        return 'ADMIN';
      }
    }
    return 'USER';
  }

  // 其他辅助方法保持不变
  static List<RegisterRequest> listFromJson(List<dynamic> json) {
    return json.map((value) => RegisterRequest.fromJson(value)).toList();
  }

  static Map<String, RegisterRequest> mapFromJson(Map<String, dynamic> json) {
    var map = <String, RegisterRequest>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
      map[key] = RegisterRequest.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of RegisterRequest-objects as value to a dart map
  static Map<String, List<RegisterRequest>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<RegisterRequest>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = RegisterRequest.listFromJson(value);
      });
    }
    return map;
  }
}
