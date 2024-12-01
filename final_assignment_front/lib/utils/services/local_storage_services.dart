import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 包含所有从本地获取数据的服务。
/// 该类设计为单例模式，用于管理本地存储操作。
class LocalStorageServices {
  /// 私有构造函数确保只能通过工厂方法创建实例。
  static final LocalStorageServices _localStorageServices =
      LocalStorageServices._internal();

  /// 工厂方法提供访问以创建实例，确保只有一个实例存在。
  factory LocalStorageServices() {
    return _localStorageServices;
  }

  /// 私有构造函数，阻止外部直接实例化。
  LocalStorageServices._internal();

  /// 保存 JWT 令牌到本地
  Future<void> saveToken(String token) async {
    await const FlutterSecureStorage().write(key: 'jwt_token', value: token);
  }

  /// 从本地存储中获取 JWT 令牌
  Future<String?> getToken() async {
    return await const FlutterSecureStorage().read(key: 'jwt_token');
  }

  /// 删除 JWT 令牌
  Future<void> deleteToken() async {
    await const FlutterSecureStorage().delete(key: 'jwt_token');
  }
}
