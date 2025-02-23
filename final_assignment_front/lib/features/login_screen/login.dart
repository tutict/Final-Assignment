import 'dart:convert';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/api/auth_controller_api.dart';
import 'package:final_assignment_front/features/model/login_request.dart';
import 'package:final_assignment_front/features/model/register_request.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

class LoginScreen extends StatefulWidget with ValidatorMixin {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late AuthControllerApi authApi;
  late String? _userRole;

  @override
  void initState() {
    super.initState();
    authApi = AuthControllerApi();
    _userRole = null;
  }

  static String determineRole(String username) {
    if (username.toLowerCase().endsWith('@admin.com')) {
      return 'ADMIN';
    }
    return 'USER';
  }

  Future<String?> _authUser(LoginData data) async {
    final username = data.name;
    final password = data.password;

    if (username.isEmpty) return '用户名不能为空';
    if (password.isEmpty) return '密码不能为空';

    try {
      final result = await authApi.apiAuthLoginPost(
        loginRequest: LoginRequest(username: username, password: password),
      );

      debugPrint('Raw result: $result');

      if (result.containsKey('jwtToken')) {
        _userRole = determineRole(username);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwtToken', result['jwtToken']);
        debugPrint('User Role: $_userRole');
        return null;
      } else {
        return result['message'] ?? '登录失败';
      }
        } on ApiException catch (e) {
      debugPrint('ApiException: ${e.message}'); // 调试输出
      return '登录失败: ${e.message}';
    } catch (e) {
      debugPrint('General Exception: $e'); // 调试输出 return '登录异常: $e';
    }
    return null;
  }

  Future<String?> _signupUser(SignupData data) async {
    final username = data.name?.trim();
    final password = data.password?.trim();

    if (username == null || username.isEmpty) return '用户名不能为空';
    if (password == null || password.isEmpty) return '密码不能为空';

    String uniqueKey = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final result = await authApi.apiAuthRegisterPost(
        registerRequest: RegisterRequest(
          username: username,
          password: password,
          idempotencyKey: uniqueKey,
        ),
      );

      if (result['status'] == 'CREATED') {
        _userRole = determineRole(username);
        return null;
      }
      return result['error'] ?? '注册失败：未知错误';
    } on ApiException catch (e) {
      return '注册失败: ${e.code} - ${e.message}';
    } catch (e) {
      return '注册异常: $e';
    }
  }

  Future<String?> _recoverPassword(String name) async {
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
          return '密码恢复成功';
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
      logo: const AssetImage(ImageRasterPath.logo4),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
        titleStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'OpenSans',
          fontWeight: FontWeight.w700,
          fontSize: 24.0,
        ),
        bodyStyle: const TextStyle(color: Colors.black),
        textFieldStyle: const TextStyle(color: Colors.black, fontSize: 16.0),
        buttonStyle: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        inputTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade200,
          contentPadding: EdgeInsets.zero,
          errorStyle: const TextStyle(backgroundColor: Colors.orange, color: Colors.white),
          labelStyle: const TextStyle(fontSize: 16.0),
        ),
        cardInitialHeight: 300.0,
        cardTopPosition: 250.0,
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
        Get.offAllNamed(_userRole == 'ADMIN' ? AppPages.initial : AppPages.userInitial);
      },
      onRecoverPassword: _recoverPassword,
    );
  }
}