/// 抽象类AMap2DController定义了地图控制器的基本操作接口。
/// 该类提供了搜索地点、移动地图视图和定位的功能，但具体实现由子类完成。
abstract class AMap2DController {
  /// 根据关键词和城市搜索地点。
  ///
  /// 参数:
  /// - keyWord：搜索的关键词。
  /// - city：默认为'哈尔滨'，可以是城市名称（中文或中文全拼）或城市代码。
  ///   用于指定搜索的范围。
  Future<void> search(String keyWord, {String city = '哈尔滨'});

  /// 移动地图视图到指定的经纬度位置。
  ///
  /// 参数:
  /// - lat：纬度。
  /// - lon：经度。
  ///
  /// 注意：此方法用于改变地图的中心点位置。
  Future<void> move(String lat, String lon);

  /// 定位到当前用户的位置。
  ///
  /// 注意：此方法用于将地图视图移动到当前用户所在的位置。
  Future<void> location();
}
