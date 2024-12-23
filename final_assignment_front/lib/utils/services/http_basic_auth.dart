import 'dart:convert';

import 'package:final_assignment_front/utils/services/authentication.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

class HttpBasicAuth implements Authentication {
  late String _username;
  late String _password;

  @override
  void applyToParams(
      List<QueryParam> queryParams, Map<String, String> headerParams) {
    // 构建 "username:password" 字符串
    String str = "$_username:$_password";
    // 进行 Base64 编码
    String encoded = base64.encode(utf8.encode(str));
    // 设置 Authorization 头
    headerParams["Authorization"] = "Basic $encoded";
  }

  set username(String username) => _username = username;

  set password(String password) => _password = password;
}
