import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:final_assignment_front/features/dashboard/views/screens/dashboard_screen.dart';

const users =  {
  'dribbble@gmail.com': '12345',
  'hunter@gmail.com': 'hunter',
};

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Duration get loginTime => const Duration(milliseconds: 2250);

  Future<String?> _authUser(LoginData data) {
    debugPrint('用户名: ${data.name}, 密码: ${data.password}');
    return Future.delayed(loginTime).then((_) {
      if (!users.containsKey(data.name)) {
        return '用户不存在';
      }
      if (users[data.name] != data.password) {
        return '用户名或密码错误';
      }
      return null;
    });
  }

  Future<String?> _signupUser(SignupData data) {
    debugPrint('名字: ${data.name}, 密码: ${data.password}');
    return Future.delayed(loginTime).then((_) {
      return null;
    });
  }

  Future<String?> _recoverPassword(String name) {
    debugPrint('名字: $name');
    return Future.delayed(loginTime).then((_) async {
      if (!users.containsKey(name)) {
        return '用户不存在';
      }
      // 这里返回 null，但确保返回的是 Future 类型
      return null;
    });
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