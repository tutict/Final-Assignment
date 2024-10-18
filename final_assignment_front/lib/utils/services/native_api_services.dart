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

  /// 私有构造函数，防止外部直接实例化。
  LocalStorageServices._internal();

  /// 保存数据到本地，可以使用SharedPreferences处理简单数据，
  /// 或者使用Sqflite处理更复杂的数据。

  /// 示例方法：使用SharedPreferences保存令牌到本地存储。
// Future<void> saveToken(String token) async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   prefs.setString('token', token);
// }

  /// 示例方法：使用SharedPreferences从本地存储中获取令牌。
// Future<String?> getToken() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('token');
// }
}
