// 预先定义的用户信息类，用于管理用户头像、姓名和邮箱
part of '../views/screens/manager_dashboard_screen.dart';

class _Profile {
  // 用户头像，类型为ImageProvider，以便在用户界面中显示
  final ImageProvider photo;

  // 用户姓名，类型为String，用于在用户界面中显示或标识用户
  final String name;

  // 用户邮箱，类型为String，用于联系或识别用户
  final String email;

  // 构造函数用于创建_Profile对象，要求photo、name和email都是必需的
  const _Profile({
    required this.photo,
    required this.name,
    required this.email,
  });
}
