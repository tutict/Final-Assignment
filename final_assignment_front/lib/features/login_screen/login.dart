import 'dart:convert';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/api/auth_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/login_request.dart';
import 'package:final_assignment_front/features/model/register_request.dart';
import 'package:final_assignment_front/shared_components/local_captcha_main.dart';
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
  bool _hasSentRegisterRequest = false; // 追踪是否已发送注册请求

  @override
  void initState() {
    super.initState();
    authApi = AuthControllerApi();
    _userRole = null;
    _hasSentRegisterRequest = false;
    if (!Get.isRegistered<ChatController>()) {
      Get.put(ChatController());
    }
    if (!Get.isRegistered<DashboardController>()) {
      Get.put(DashboardController());
    }
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

    if (username.isEmpty) return '用户邮箱不能为空';
    if (password.isEmpty) return '密码不能为空';

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(username)) {
      return '请输入有效的邮箱地址';
    }

    try {
      final result = await authApi.apiAuthLoginPost(
        loginRequest: LoginRequest(username: username, password: password),
      );

      debugPrint('Login raw result: $result');

      if (result.containsKey('jwtToken')) {
        _userRole = determineRole(username);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwtToken', result['jwtToken']);
        await prefs.setString('userRole', _userRole!);

        final userData = result['user'] ?? {};
        final String name = userData['name'] ?? username.split('@').first;
        final String email = userData['email'] ?? username;

        final DashboardController dashboardController =
            Get.find<DashboardController>();
        dashboardController.updateCurrentUser(name, email);

        final UserDashboardController userDashboardController =
            Get.find<UserDashboardController>();
        userDashboardController.updateCurrentUser(name, email);

        Get.find<ChatController>().setUserRole(_userRole!);
        debugPrint('User Role: $_userRole, Name: $name, Email: $email');
        return null;
      } else {
        return result['message'] ?? '登录失败';
      }
    } on ApiException catch (e) {
      debugPrint('ApiException in login: ${e.message}');
      return '登录失败: ${e.message}';
    } catch (e) {
      debugPrint('General Exception in login: $e');
      return '登录异常: $e';
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    final username = data.name?.trim();
    final password = data.password?.trim();

    if (username == null || username.isEmpty) return '用户邮箱不能为空';
    if (password == null || password.isEmpty) return '密码不能为空';

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(username)) {
      return '请输入有效的邮箱地址';
    }

    if (_hasSentRegisterRequest) {
      return '注册请求已发送，请等待处理';
    }

    final bool? isCaptchaValid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocalCaptchaMain(),
    );

    debugPrint('Signup captcha result: $isCaptchaValid');
    if (isCaptchaValid != true) {
      return '用户已取消注册账号';
    }

    String uniqueKey = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      // 注册请求
      debugPrint('Sending register request for $username');
      final registerResult = await authApi.apiAuthRegisterPost(
        registerRequest: RegisterRequest(
          username: username,
          password: password,
          idempotencyKey: uniqueKey,
        ),
      );

      debugPrint('Signup raw result: $registerResult');

      if (registerResult['status'] == 'CREATED') {
        _hasSentRegisterRequest = true;

        // 立即调用登录请求
        debugPrint('Sending login request for $username after signup');
        final loginResult = await authApi.apiAuthLoginPost(
          loginRequest: LoginRequest(username: username, password: password),
        );

        debugPrint('Login after signup raw result: $loginResult');

        if (loginResult.containsKey('jwtToken')) {
          _userRole = determineRole(username);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwtToken', loginResult['jwtToken']);
          await prefs.setString('userRole', _userRole!);
          debugPrint('JWT saved: ${loginResult['jwtToken']}');
          debugPrint('Role saved: $_userRole');

          final userData = loginResult['user'] ?? {};
          final String name = userData['name'] ?? username.split('@').first;
          final String email = userData['email'] ?? username;

          final DashboardController dashboardController =
              Get.find<DashboardController>();
          dashboardController.updateCurrentUser(name, email);

          final UserDashboardController userDashboardController =
              Get.find<UserDashboardController>();
          userDashboardController.updateCurrentUser(name, email);

          Get.find<ChatController>().setUserRole(_userRole!);
          debugPrint(
              'User Role after signup and login: $_userRole, Name: $name, Email: $email');
          return null;
        } else {
          debugPrint('Login failed after signup: $loginResult');
          return loginResult['message'] ?? '注册成功，但登录失败';
        }
      }
      debugPrint('Register failed: $registerResult');
      return registerResult['error'] ?? '注册失败：未知错误';
    } on ApiException catch (e) {
      debugPrint('ApiException in signup: ${e.code} - ${e.message}');
      return '注册失败: ${e.code} - ${e.message}';
    } catch (e) {
      debugPrint('General Exception in signup: $e');
      return '注册异常: $e';
    }
  }

  Future<String?> _recoverPassword(String name) async {
    final bool? isCaptchaValid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocalCaptchaMain(),
    );

    debugPrint('Recover captcha result: $isCaptchaValid');

    if (isCaptchaValid != true) {
      debugPrint('Captcha validation failed or cancelled');
      return '密码重置已取消';
    }

    try {
      const url = 'http://localhost:8081/api/auth/recoverPassword';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': name}),
      );
      debugPrint(
          'Recover password response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          debugPrint('Password recovery successful');
          return '密码恢复成功';
        } else {
          debugPrint('Password recovery failed: ${data['message']}');
          return data['message'] ?? '密码恢复失败';
        }
      } else {
        debugPrint(
            'Recover password failed with status: ${response.statusCode}');
        return '密码恢复失败：状态码 ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('Recover password exception: $e');
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
        titleStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'OpenSans',
          fontWeight: FontWeight.w700,
          fontSize: 24.0,
        ),
        bodyStyle: const TextStyle(color: Colors.black),
        textFieldStyle: const TextStyle(color: Colors.black, fontSize: 16.0),
        buttonStyle:
            const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        inputTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade200,
          contentPadding: EdgeInsets.zero,
          errorStyle: const TextStyle(
              backgroundColor: Colors.orange, color: Colors.white),
          labelStyle: const TextStyle(fontSize: 16.0),
        ),
        cardInitialHeight: 300.0,
        cardTopPosition: 250.0,
      ),
      messages: LoginMessages(
        passwordHint: '密码',
        userHint: '用户邮箱',
        forgotPasswordButton: '忘记密码？',
        confirmPasswordHint: '再次输入密码',
        loginButton: '登录',
        signupButton: '注册',
        recoverPasswordButton: '重置密码',
        recoverCodePasswordDescription: '请输入您的用户邮箱',
        goBackButton: '返回',
        confirmPasswordError: '密码输入不匹配',
        confirmSignupSuccess: '注册成功',
        confirmRecoverSuccess: '密码重置成功',
        recoverPasswordDescription: '请输入您的用户邮箱，我们将为您重置密码',
        recoverPasswordIntro: '重置密码',
      ),
      onSubmitAnimationCompleted: () {
        Get.offAllNamed(
            _userRole == 'ADMIN' ? AppPages.initial : AppPages.userInitial);
      },
      onRecoverPassword: _recoverPassword,
    );
  }
}
