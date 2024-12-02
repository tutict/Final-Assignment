import 'dart:convert';

import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/utils/mixins/app_mixins.dart';
import 'package:final_assignment_front/utils/services/app_config.dart';
import 'package:final_assignment_front/utils/services/local_storage_services.dart';
import 'package:final_assignment_front/utils/services/message_provider.dart';
import 'package:final_assignment_front/utils/services/rest_api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// 登录屏幕 StatefulWidget
class LoginScreen extends StatefulWidget with ValidatorMixin {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// 登录屏幕状态管理类
class _LoginScreenState extends State<LoginScreen> {
  late RestApiServices restApiServices;
  MessageProvider? messageProvider;

  @override
  void initState() {
    super.initState();
    restApiServices = RestApiServices();

    // 尝试初始化 WebSocket 连接
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        messageProvider = Provider.of<MessageProvider>(context, listen: false);
        String fullUrl = AppConfig.getFullUrl(AppConfig.userManagementEndpoint);
        restApiServices.initWebSocket(fullUrl, messageProvider!);
      } catch (e) {
        debugPrint('WebSocket 连接初始化失败: $e');
      }
    });
  }

  @override
  void dispose() {
    // 关闭 WebSocket 连接
    restApiServices.closeWebSocket();
    super.dispose();
  }

  /// 登录动画持续时间
  Duration get loginTime => const Duration(milliseconds: 2250);

  /// 用户认证逻辑
  Future<String?> _authUser(LoginData data) async {
    debugPrint('用户名: ${data.name}, 密码: ${data.password}');

    // 检查 WebSocket 是否初始化
    if (messageProvider == null) {
      return 'WebSocket connection is not ready. Please wait and try again.';
    }

    restApiServices.sendMessage(jsonEncode({
      'action': 'login',
      'username': data.name,
      'password': data.password,
    }));

    // 等待登录响应
    final responseData = await messageProvider!.waitForMessage('loginResponse');

    if (responseData != null && responseData['status'] == 'success') {
      // 存储 JWT 令牌
      String token = responseData['token'];
      await LocalStorageServices().saveToken(token);
      debugPrint('JWT token saved');

      // 导航到仪表板
      Get.offAllNamed(AppPages.initial);
      return null;
    } else {
      return responseData?['message'] ?? '登录失败';
    }
  }

  /// 用户注册逻辑
  Future<String?> _signupUser(SignupData data) async {
    if (messageProvider == null) {
      return 'WebSocket connection is not ready. Please wait and try again.';
    }

    restApiServices.sendMessage(jsonEncode({
      'action': 'signup',
      'username': data.name,
      'password': data.password,
    }));

    // 等待注册响应
    final responseData =
        await messageProvider!.waitForMessage('signupResponse');

    if (responseData != null && responseData['status'] == 'success') {
      return null;
    } else {
      return responseData?['message'] ?? '注册失败';
    }
  }

  /// 密码恢复逻辑
  Future<String?> _recoverPassword(String name) async {
    if (messageProvider == null) {
      return 'WebSocket connection is not ready. Please wait and try again.';
    }

    restApiServices.sendMessage(
        jsonEncode({'action': 'recoverPassword', 'username': name}));

    // 等待密码恢复响应
    final responseData =
        await messageProvider!.waitForMessage('recoverPasswordResponse');

    if (responseData != null && responseData['status'] == 'success') {
      return null;
    } else {
      return responseData?['message'] ?? '密码恢复失败';
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
