import 'package:flutter/material.dart';

/// 用户个人资料类
///
/// Profile 类用于表示用户的个人资料信息，包含用户的头像、姓名和邮箱
/// 该类主要用作数据模型，将用户信息以不可变的方式存储
class Profile {
  // 用户头像，使用 ImageProvider 类型，支持多种图像来源
  final ImageProvider photo;

  // 用户姓名，使用 String 类型
  final String name;

  // 用户邮箱，使用 String 类型
  final String email;

  /// Profile 类的构造函数
  ///
  /// @param photo 用户的头像，必须提供
  /// @param name 用户的姓名，必须提供
  /// @param email 用户的邮箱地址，必须提供
  const Profile({
    required this.photo,
    required this.name,
    required this.email,
  });
}