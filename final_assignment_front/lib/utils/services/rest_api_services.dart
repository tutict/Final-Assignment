/// 包含所有从服务器获取数据的服务。
class RestApiServices {
  // RestApiServices 的单例实例。
  static final RestApiServices _restApiServices = RestApiServices._internal();

  // 工厂方法，用于获取 RestApiServices 的单例实例。
  factory RestApiServices() {
    return _restApiServices;
  }

  // 私有构造函数，防止直接实例化。
  RestApiServices._internal();

// 从服务器获取数据时，可以使用 Http 用于简单的功能，或使用 Dio 用于更复杂的功能。

// 示例：
// Future<ProductDetail?> getProductDetail(int id) async {
//   var uri = Uri.parse(ApiPath.product + "/$id");
//   try {
//     return await Dio().getUri(uri);
//   } on DioError catch (e) {
//     print(e);
//   } catch (e) {
//     print(e);
//   }
// }
}
