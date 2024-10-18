import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:final_assignment_front/features/dashboard/views/screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/config/websocket/websocket_service.dart';

import '../../../config/routes/app_pages.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late WebSocketService webSocketService;

  @override
  void initState() {
    super.initState();
    webSocketService = WebSocketService();
  }

  @override
  void dispose() {
    webSocketService.close();
    super.dispose();
  }

  Duration get loginTime => const Duration(milliseconds: 2250);

  Future<String?> _authUser(LoginData data) async {
    debugPrint('用户名: ${data.name}, 密码: ${data.password}');
    webSocketService.sendMessage(jsonEncode({
      'action': 'users/login',
      'username': data.name,
      'password': data.password
    }));

    final response = await webSocketService.getMessages().firstWhere((message) {
      final decodedMessage = jsonDecode(message);
      return decodedMessage['action'] == 'login';
    });

    final decodedMessage = jsonDecode(response);
    if (decodedMessage['status'] == 'error') {
      return decodedMessage['message'];
    } else {
      // 安全存储 JWT 令牌（例如，使用 flutter_secure_storage）
      String token = decodedMessage['token'];
      // 导航到仪表板
      Get.toNamed(Routes.dashboard);
      return null;
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    debugPrint('名字: ${data.name}, 密码: ${data.password}');
    webSocketService.sendMessage(jsonEncode(
        {'action': 'users', 'username': data.name, 'password': data.password}));

    final response = await webSocketService.getMessages().firstWhere((message) {
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

  Future<String?> _recoverPassword(String name) async {
    debugPrint('名字: $name');
    webSocketService
        .sendMessage(jsonEncode({'action': 'auth/recover', 'username': name}));

    final response = await webSocketService.getMessages().firstWhere((message) {
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
        titleStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'OpenSans',
          fontWeight: FontWeight.w700,
        ),
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
