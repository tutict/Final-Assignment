/// POI搜索类，用于封装地点搜索的相关信息
class PoiSearch {
  /// 构造函数
  /// @param cityCode 城市代码
  /// @param cityName 城市名称
  /// @param provinceName 省份名称
  /// @param title 地点标题
  /// @param adName 地址名称
  /// @param provinceCode 省份代码
  /// @param latitude 纬度
  /// @param longitude 经度
  PoiSearch({
    this.cityCode,
    this.cityName,
    this.provinceName,
    this.title,
    this.adName,
    this.provinceCode,
    this.latitude,
    this.longitude,
  });

  /// 从JSON映射构造函数
  /// @param map 包含地点信息的JSON映射
  PoiSearch.fromJsonMap(Map<String, dynamic> map)
      : cityCode = map['cityCode'] as String?,
        cityName = map['cityName'] as String?,
        provinceName = map['provinceName'] as String?,
        title = map['title'] as String?,
        adName = map['adName'] as String?,
        provinceCode = map['provinceCode'] as String?,
        latitude = map['latitude'] as String?,
        longitude = map['longitude'] as String?;

  /// 城市代码
  String? cityCode;

  /// 城市名称
  String? cityName;

  /// 省份名称
  String? provinceName;

  /// 地点标题
  String? title;

  /// 地址名称
  String? adName;

  /// 省份代码
  String? provinceCode;

  /// 纬度
  String? latitude;

  /// 经度
  String? longitude;

  /// 将POI搜索对象转换为JSON映射
  /// @return 包含POI搜索信息的JSON映射
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cityCode'] = cityCode;
    data['cityName'] = cityName;
    data['provinceName'] = provinceName;
    data['title'] = title;
    data['adName'] = adName;
    data['provinceCode'] = provinceCode;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    return data;
  }
}
