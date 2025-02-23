class LoginRequest {
  String? username;
  String? password;

  LoginRequest({required this.username, required this.password}); // 修复构造函数

  @override
  String toString() {
    return 'LoginRequest[username=$username, password=$password]';
  }

  LoginRequest.fromJson(Map<String, dynamic> json) {
    username = json['username'];
    password = json['password'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (username != null) {
      json['username'] = username;
    }
    if (password != null) {
      json['password'] = password;
    }
    return json;
  }

  static List<LoginRequest> listFromJson(List<dynamic> json) {
    return json.map((value) => LoginRequest.fromJson(value)).toList();
  }

  static Map<String, LoginRequest> mapFromJson(Map<String, dynamic> json) {
    var map = <String, LoginRequest>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
      map[key] = LoginRequest.fromJson(value));
    }
    return map;
  }

  static Map<String, List<LoginRequest>> mapListFromJson(Map<String, dynamic> json) {
    var map = <String, List<LoginRequest>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = LoginRequest.listFromJson(value);
      });
    }
    return map;
  }
}