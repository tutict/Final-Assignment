import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import '../../dashboard/views/user_dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Duration get loginTime => const Duration(milliseconds: 2250);

  Future<String?> _authUser(LoginData data) {
    debugPrint('名字: ${data.name}, 密码: ${data.password}');
    return Future.delayed(loginTime).then((_) {
      if (!users.containsKey(data.name)) {
        return '用户不存在';
      }
      if (users[data.name] != data.password) {
        return '用户或者密码错误';
      }
      return null;
    });
  }

  Future<String?> _signupUser(SignupData data) {
    debugPrint('登录用户: ${data.name}, 密码: ${data.password}');
    return Future.delayed(loginTime).then((_) {
      return null;
    });
  }

  Future<String> _recoverPassword(String name) {
    debugPrint('名字: $name');
    return Future.delayed(loginTime).then((_) {
      if (!users.containsKey(name)) {
        return '用户不存在';
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: '交通违法行为处理管理系统',
      logo: const AssetImage('assets/images/ecorp-lightblue.png'),
      onLogin: _authUser,
      onSignup: _signupUser,
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const UserDashboardScreen(),
        ));
      },
      onRecoverPassword: _recoverPassword,
      messages: LoginMessages(
        userHint: '用户名',
        passwordHint: '密码',
        confirmPasswordHint: 'Confirm',
        loginButton: '登录',
        signupButton: '注册',
        forgotPasswordButton: '忘记密码？',
        recoverPasswordButton: '帮助',
        goBackButton: '返回',
        confirmPasswordError: '两次密码不一致',
        recoverPasswordDescription:
        'Lorem Ipsum is simply dummy text of the printing and typesetting industry',
        recoverPasswordSuccess: '重设密码成功',
      ),
    );
  }
}