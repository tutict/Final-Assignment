import 'package:flutter/foundation.dart';
import 'package:final_assignment_front/config/map/flutter_2d_amap.dart';
import 'package:final_assignment_front/config/mapjs/amapjs.dart';
import 'package:js/js.dart';

/// 高德地图2D网页控制器类，继承自AMap2DController
class AMap2DWebController extends AMap2DController {
  /// 构造函数
  AMap2DWebController(this._aMap, this._widget) {
    // 初始化搜索选项
    _placeSearchOptions = PlaceSearchOptions(
      extensions: 'all',
      type: _kType,
      pageIndex: 1,
      pageSize: 50,
    );

    // 监听地图点击事件，点击时搜索周边地点
    _aMap.on('click', allowInterop((event) {
      searchNearBy(LngLat(event.lnglat.getLng(), event.lnglat.getLat()));
    }));

    // 定位插件初始化
    _geolocation = Geolocation(GeolocationOptions(
      timeout: 15000,
      buttonPosition: 'RT',
      buttonOffset: Pixel(10, 20),
      zoomToAccuracy: true,
      enableHighAccuracy: true,
    ));

    _aMap.addControl(_geolocation);
    location();
  }

  // 高德地图视图组件
  final AMap2DView _widget;

  // 高德地图实例
  final AMap _aMap;

  // 定位插件实例
  late Geolocation _geolocation;

  // 标记选项
  MarkerOptions? _markerOptions;

  // 搜索选项
  late PlaceSearchOptions _placeSearchOptions;

  // 地点类型常量
  static const String _kType =
      '010000|010100|020000|030000|040000|050000|050100|060000|060100|060200|060300|060400|070000|080000|080100|080300|080500|080600|090000|090100|090200|090300|100000|100100|110000|110100|120000|120200|120300|130000|140000|141200|150000|150100|150200|160000|160100|170000|170100|170200|180000|190000|200000';

  /// 根据关键字和城市搜索地点
  @override
  Future<void> search(String keyWord, {city = ''}) async {
    if (!_widget.isPoiSearch) {
      return;
    }
    final PlaceSearch placeSearch = PlaceSearch(_placeSearchOptions);
    placeSearch.setCity(city);
    placeSearch.search(keyWord, searchResult);
    return Future.value();
  }

  /// 移动地图中心点到指定经纬度
  @override
  Future<void> move(String lat, String lon) async {
    final LngLat lngLat = LngLat(double.parse(lon), double.parse(lat));
    if (_markerOptions == null) {
      _markerOptions = MarkerOptions(
          position: lngLat,
          icon: AMapIcon(IconOptions(
            size: Size(26, 34),
            imageSize: Size(26, 34),
            image:
                'https://a.amap.com/jsapi_demos/static/demo-center/icons/poi-marker-default.png',
          )),
          offset: Pixel(-13, -34),
          anchor: 'bottom-center');
    } else {
      _markerOptions?.position = lngLat;
    }
    _aMap.clearMap();
    _aMap.add(Marker(_markerOptions!));
    return Future.value();
  }

  /// 获取当前位置并移动地图中心点到该位置
  @override
  Future<void> location() async {
    _geolocation.getCurrentPosition(allowInterop((status, result) {
      if (status == 'complete') {
        _aMap.setZoom(17);
        _aMap.setCenter(result.position);
        searchNearBy(result.position);
      } else {
        if (kDebugMode) {
          print(result.message);
        }
      }
    }));
    return Future.value();
  }

  /// 根据经纬度搜索周边地点
  void searchNearBy(LngLat lngLat) {
    if (!_widget.isPoiSearch) {
      return;
    }
    final PlaceSearch placeSearch = PlaceSearch(_placeSearchOptions);
    placeSearch.searchNearBy('', lngLat, 2000, searchResult);
  }

  /// 搜索结果回调函数
  Function(String status, SearchResult result) get searchResult =>
      allowInterop((status, result) {
        final List<PoiSearch> list = <PoiSearch>[];
        if (status == 'complete') {
          result.poiList?.pois?.forEach((dynamic poi) {
            if (poi is Poi) {
              final PoiSearch poiSearch = PoiSearch(
                cityCode: poi.citycode,
                cityName: poi.cityname,
                provinceName: poi.pname,
                title: poi.name,
                adName: poi.adname,
                provinceCode: poi.pcode,
                latitude: poi.location.getLat().toString(),
                longitude: poi.location.getLng().toString(),
              );
              list.add(poiSearch);
            }
          });
        } else if (status == 'no_data') {
          if (kDebugMode) {
            print('无返回结果');
          }
        } else {
          if (kDebugMode) {
            print(result);
          }
        }
        if (list.isNotEmpty) {
          _aMap.setZoom(17);
          move(list[0].latitude!, list[0].longitude!);
        }
        if (_widget.onPoiSearched != null) {
          _widget.onPoiSearched!(list);
        }
      });
}
