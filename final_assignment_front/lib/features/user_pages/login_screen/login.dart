import 'package:final_assignment_front/utils/services/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:final_assignment_front/features/dashboard/views/screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/utils/services/rest_api_services.dart';

import '../../../config/routes/app_pages.dart';

/// 登录屏幕 StatefulWidget
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// 登录屏幕状态管理类
class _LoginScreenState extends State<LoginScreen> {
  late RestApiServices restApiServices;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    restApiServices = RestApiServices();
    restApiServices.initWebSocket(AppConfig.userManagementEndpoint);
  }

  /// 登录动画持续时间
  Duration get loginTime => const Duration(milliseconds: 2250);

  /// 用户认证逻辑
  Future<String?> _authUser(LoginData data) async {
    debugPrint('用户名: \${data.name}, 密码: \${data.password}');
    restApiServices.sendMessage(jsonEncode({
      'action': 'users/login',
      'username': data.name,
      'password': data.password
    }));

    final response = await restApiServices.getMessages().firstWhere((message) {
      final decodedMessage = jsonDecode(message);
      return decodedMessage['action'] == 'login';
    });

    final decodedMessage = jsonDecode(response);
    if (decodedMessage['status'] == 'error') {
      return decodedMessage['message'];
    } else {
      // 安全存储 JWT 令牌
      String token = decodedMessage['token'];
      await _secureStorage.write(key: 'jwt_token', value: token);
      debugPrint('JWT token saved');
      // 导航到仪表板
      Get.toNamed(AppPages.initial);
      return null;
    }
  }

  /// 用户注册逻辑
  Future<String?> _signupUser(SignupData data) async {
    debugPrint('名字: \${data.name}, 密码: \${data.password}');
    restApiServices.sendMessage(jsonEncode(
        {'action': 'users', 'username': data.name, 'password': data.password}));

    final response = await restApiServices.getMessages().firstWhere((message) {
      final decodedMessage = jsonDecode(message);
      return decodedMessage['action'] == 'signup';
    });

    final decodedMessage = jsonDecode(response);
    if (decodedMessage['status'] == 'error') {
      return decodedMessage['message'];
    } else {
      return null;
    }
  }

  /// 密码恢复逻辑
  Future<String?> _recoverPassword(String name) async {
    debugPrint('名字: $name');
    restApiServices
        .sendMessage(jsonEncode({'action': 'auth/recover', 'username': name}));

    final response = await restApiServices.getMessages().firstWhere((message) {
      final decodedMessage = jsonDecode(message);
      return decodedMessage['action'] == 'recover';
    });

    final decodedMessage = jsonDecode(response);
    if (decodedMessage['status'] == 'error') {
      return decodedMessage['message'];
    } else {
      return null;
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
        userHint: '用户邮箱',
        forgotPasswordButton: '忘记密码？',
        confirmPasswordHint: '再次输入密码',
        loginButton: '登录',
        signupButton: '注册',
        recoverPasswordButton: '修改密码',
        recoverCodePasswordDescription: '请输入您的邮箱',
        goBackButton: '返回',
        confirmPasswordError: '密码输入不匹配',
        confirmSignupSuccess: '注册成功',
        confirmRecoverSuccess: '密码修改成功',
        recoverPasswordDescription: '请输入您的邮箱,我们将确认您的邮箱是否存在',
        recoverPasswordIntro: '重新设置密码',
      ),
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ));
      },
      onRecoverPassword: _recoverPassword,
    );
  }
}
