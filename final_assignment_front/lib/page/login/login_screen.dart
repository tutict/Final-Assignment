import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:final_assignment_front/features/dashboard/views/screens/dashboard_screen.dart';

import '../../config/routes/app_pages.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late WebSocketChannel channel;
  final String websocketUrl = 'wss://localhost:8080/ws'; // 更新为实际的 URL

  @override
  void initState() {
    super.initState();
    channel = IOWebSocketChannel.connect(websocketUrl);
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  Duration get loginTime => const Duration(milliseconds: 2250);

  Future<String?> _authUser(LoginData data) async {
    debugPrint('用户名: ${data.name}, 密码: ${data.password}');
    channel.sink.add(jsonEncode({
      'action': 'login',
      'username': data.name,
      'password': data.password
    }));

    final response = await channel.stream.firstWhere((message) {
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
    channel.sink.add(jsonEncode({
      'action': 'signup',
      'username': data.name,
      'password': data.password
    }));

    final response = await channel.stream.firstWhere((message) {
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
    channel.sink.add(jsonEncode({
      'action': 'recover',
      'username': name
    }));

    final response = await channel.stream.firstWhere((message) {
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
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ));
      },
      onRecoverPassword: _recoverPassword,
    );
  }
}
