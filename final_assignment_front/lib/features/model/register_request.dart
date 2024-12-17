class RegisterRequest {
  String? username;

  String? password;

  bool? admin;

  RegisterRequest();

  @override
  String toString() {
    return 'RegisterRequest[username=$username, password=$password, admin=$admin, ]';
  }

  RegisterRequest.fromJson(Map<String, dynamic> json) {
    username = json['username'];
    password = json['password'];
    admin = json['admin'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (username != null) {
      json['username'] = username;
    }
    if (password != null) {
      json['password'] = password;
    }
    if (admin != null) {
      json['admin'] = admin;
    }
    return json;
  }

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
