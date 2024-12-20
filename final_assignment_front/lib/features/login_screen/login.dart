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
import 'package:http/http.dart' as http;

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

  // 尝试初始化 WebSocket 连接
  @override
  void initState() {
    super.initState();
    restApiServices = RestApiServices();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // 获取全局的 MessageProvider 实例
        messageProvider = Provider.of<MessageProvider>(context, listen: false);

        if (messageProvider != null) {
          String fullUrl = AppConfig.getFullUrl(AppConfig.authControllerEndpoint);
          debugPrint('尝试连接 WebSocket，URL: $fullUrl');

          // 初始化 WebSocket 连接
          bool isConnected = await restApiServices.initWebSocket(fullUrl, messageProvider!);

          if (isConnected) {
            debugPrint('WebSocket 连接初始化成功');
          } else {
            debugPrint('WebSocket 连接初始化失败，无法建立连接');
          }
        } else {
          debugPrint('MessageProvider 未初始化，无法建立 WebSocket 连接');
        }
      } catch (e, stacktrace) {
        debugPrint('WebSocket 连接初始化过程中发生错误: $e\n$stacktrace');
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

    if (messageProvider == null) {
      // 使用 HTTP 请求进行登录
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.authControllerEndpoint}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': data.name,
          'password': data.password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          String token = responseData['token'];
          await LocalStorageServices().saveToken(token);
          debugPrint('JWT token saved');
          Get.offAllNamed(AppPages.initial);
          return null;
        } else {
          return responseData['message'] ?? '登录失败';
        }
      } else {
        return 'HTTP 请求失败，状态码: ${response.statusCode}';
      }
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
      // 使用 HTTP 请求进行注册
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.authControllerEndpoint}/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': data.name,
          'password': data.password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          return null;
        } else {
          return responseData['message'] ?? '注册失败';
        }
      } else {
        return 'HTTP 请求失败，状态码: ${response.statusCode}';
      }
    }

    restApiServices.sendMessage(jsonEncode({
      'action': 'signup',
      'username': data.name,
      'password': data.password,
    }));

    // 等待注册响应
    final responseData = await messageProvider!.waitForMessage('signupResponse');

    if (responseData != null && responseData['status'] == 'success') {
      return null;
    } else {
      return responseData?['message'] ?? '注册失败';
    }
  }

  /// 密码恢复逻辑
  Future<String?> _recoverPassword(String name) async {
    if (messageProvider == null) {
      // 使用 HTTP 请求进行密码恢复
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.authControllerEndpoint}/recoverPassword'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': name}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          return null;
        } else {
          return responseData['message'] ?? '密码恢复失败';
        }
      } else {
        return 'HTTP 请求失败，状态码: ${response.statusCode}';
      }
    }

    restApiServices.sendMessage(jsonEncode({'action': 'recoverPassword', 'username': name}));

    // 等待密码恢复响应
    final responseData = await messageProvider!.waitForMessage('recoverPasswordResponse');

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
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