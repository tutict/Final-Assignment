abstract class AMap2DController {

  /// city：cityName（中文或中文全拼）、cityCode均可
  Future<void> search(String keyWord, {String city = '哈尔滨'});

  Future<void> move(String lat, String lon);

  Future<void> location();
}