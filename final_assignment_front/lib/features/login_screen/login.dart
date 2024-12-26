import 'dart:convert';

import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/auth_controller_api.dart';
import 'package:final_assignment_front/features/model/login_request.dart';
import 'package:final_assignment_front/features/model/register_request.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:get/get.dart'; // 如果你需要路由跳转
import 'package:http/http.dart' as http;

/// 这个 mixin 只是演示，如果你有自己的校验函数，可自行保留或删除
mixin ValidatorMixin {
  String? validateUsername(String? val) {
    if (val == null || val.isEmpty) return '用户名不能为空';
    return null;
  }

  String? validatePassword(String? val) {
    if (val == null || val.isEmpty) return '密码不能为空';
    if (val.length < 3) return '密码太短';
    return null;
  }
}

/// 登录界面
class LoginScreen extends StatefulWidget with ValidatorMixin {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// 登录界面状态
class _LoginScreenState extends State<LoginScreen> {
  // 直接使用 AuthControllerApi
  late AuthControllerApi authApi;

  @override
  void initState() {
    super.initState();
    authApi = AuthControllerApi();
    // 这样会使用默认的 defaultApiClient (basePath = http://localhost:8081)，
    // 如果你想自定义 basePath，可以在构造时传入一个新的 ApiClient(basePath:'...')
  }

  /// 用户登录逻辑
  Future<String?> _authUser(LoginData data) async {
    final username = data.name;
    final password = data.password;

    try {
      // 发起登录请求
      final result = await authApi.apiAuthLoginPost(
        loginRequest: LoginRequest(username: username, password: password),
      );

      // 这里 result 的类型是 `Object?` (通常会被解析为 Map 或其他)
      // 你需要看后台返回什么格式。例如:
      // {
      //   "status": "success",
      //   "token": "xxxxxx"
      // }
      //
      // 如果是 `null`，说明响应体为空
      if (result == null) {
        return '登录失败：响应体为空';
      }

      // 如果后端返回了一个 Map<String, dynamic>:
      if (result is Map<String, dynamic>) {
        if (result['status'] == 'success') {
          // 拿到 token
          String token = result['token'] ?? '';
          // 可以在此处存储 token，比如 SharedPreferences
          // 登录成功则返回 null（表示无错误消息）
          return null;
        } else {
          // 如果 status != success
          return result['message'] ?? '登录失败';
        }
      } else {
        // 如果不是 Map，可能是别的类型
        return '未识别的响应数据: $result';
      }
    } on ApiException catch (e) {
      // 如果后端返回 4xx/5xx，ApiException 会被抛出
      return '登录失败: ${e.message}';
    } catch (e) {
      // 其他未知异常
      return '登录异常: $e';
    }
  }

  /// 用户注册逻辑
  Future<String?> _signupUser(SignupData data) async {
    final username = data.name?.trim();
    final password = data.password?.trim();

    if (username == null || username.isEmpty) {
      return '用户名不能为空';
    }
    if (password == null || password.isEmpty) {
      return '密码不能为空';
    }

    try {
      final result = await authApi.apiAuthRegisterPost(
        registerRequest: RegisterRequest(
          username: username,
          password: password,
          // 如果需要设置 admin，可以在这里传递
          // admin: false,
        ),
      );
      if (result == null) {
        return '注册失败：响应体为空';
      }
      if (result is Map<String, dynamic>) {
        if (result['status'] == 'success') {
          // 注册成功
          return null;
        } else {
          return result['message'] ?? '注册失败';
        }
      } else {
        return '未知注册响应数据: $result';
      }
    } on ApiException catch (e) {
      return '注册失败: ${e.message}';
    } catch (e) {
      return '注册异常: $e';
    }
  }

  /// 忘记密码逻辑
  Future<String?> _recoverPassword(String name) async {
    // 这里演示：没有专门的 recoverPassword 接口，就随便 HTTP 调用下
    // 如果后端确实有，你可以在 AuthControllerApi 里加一个 apiAuthRecoverPasswordPost
    try {
      const url = 'http://localhost:8081/api/auth/recoverPassword';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': name}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return null; // 表示无错误
        } else {
          return data['message'] ?? '密码恢复失败';
        }
      } else {
        return '密码恢复失败：状态码 ${response.statusCode}';
      }
    } catch (e) {
      return '密码恢复异常: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: '交通违法行为处理管理系统',
      logo: const AssetImage('assets/images/raster/logo-1.png'),
      onLogin: _authUser,
      onSignup: _signupUser,
      theme: LoginTheme(
        primaryColor: Colors.blue,
        accentColor: Colors.amberAccent,
        errorColor: Colors.deepOrange,
        pageColorLight: Colors.lightBlueAccent,
        pageColorDark: Colors.blueGrey,
        buttonTheme: const LoginButtonTheme(
          splashColor: Colors.lightBlueAccent,
          backgroundColor: Colors.blue,
          highlightColor: Colors.lightBlue,
          elevation: 9.0,
          highlightElevation: 6.0,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
        titleStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'OpenSans',
          fontWeight: FontWeight.w700,
          fontSize: 24.0,
        ),
        bodyStyle: const TextStyle(
          color: Colors.white,
        ),
        textFieldStyle: const TextStyle(
          color: Colors.black,
          fontSize: 16.0,
        ),
        buttonStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        inputTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white70,
          contentPadding: EdgeInsets.zero,
          errorStyle: TextStyle(
            backgroundColor: Colors.orange,
            color: Colors.white,
          ),
          labelStyle: TextStyle(fontSize: 16.0),
        ),
        cardInitialHeight: 300.0,
        cardTopPosition: 100.0,
      ),
      messages: LoginMessages(
        passwordHint: '密码',
        userHint: '用户名',
        forgotPasswordButton: '忘记密码？',
        confirmPasswordHint: '再次输入密码',
        loginButton: '登录',
        signupButton: '注册',
        recoverPasswordButton: '重置密码',
        recoverCodePasswordDescription: '请输入您的用户名',
        goBackButton: '返回',
        confirmPasswordError: '密码输入不匹配',
        confirmSignupSuccess: '注册成功',
        confirmRecoverSuccess: '密码重置成功',
        recoverPasswordDescription: '请输入您的用户名，我们将为您重置密码',
        recoverPasswordIntro: '重置密码',
      ),
      onSubmitAnimationCompleted: () {
        // 登录成功后跳转到仪表板
        Get.offAllNamed(AppPages.initial);
      },
      onRecoverPassword: _recoverPassword,
    );
  }
}
