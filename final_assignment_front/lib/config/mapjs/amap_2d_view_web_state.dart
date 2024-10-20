import 'dart:html' show DivElement;
import 'dart:js_util' show allowInterop, promiseToFuture;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:final_assignment_front/config/map/flutter_2d_amap.dart';
import 'package:final_assignment_front/config/mapjs/amap_2d_web_controller.dart';
import 'package:final_assignment_front/config/mapjs/amapjs.dart';
import 'package:final_assignment_front/config/mapjs/loaderjs.dart';

/// 高德地图2D视图的状态类
class AMap2DViewState extends State<AMap2DView> {

  /// 加载的插件
  final List<String> plugins = <String>['AMap.Geolocation', 'AMap.PlaceSearch', 'AMap.Scale', 'AMap.ToolBar'];

  late AMap _aMap;
  late String _divId;
  late DivElement _element;

  /// 当平台视图创建时调用
  void _onPlatformViewCreated() {
    // 加载高德地图JS API
    final Object promise = load(LoaderOptions(
      key: Flutter2dAMap.webKey,
      version: '1.4.15', // 2.0需要修改GeolocationOptions属性
      plugins: plugins,
    )) as Object;

    // 将Promise转换为Future
    promiseToFuture<dynamic>(promise).then((dynamic value){
      final MapOptions mapOptions = MapOptions(
        zoom: 11,
        resizeEnable: true,
      );
      /// 无法使用id https://github.com/flutter/flutter/issues/40080
      _aMap = AMap(_element, mapOptions);
      /// 加载插件
      _aMap.plugin(plugins, allowInterop(() {
        _aMap.addControl(Scale());
        _aMap.addControl(ToolBar());

        final AMap2DWebController controller = AMap2DWebController(_aMap, widget);
        if (widget.onAMap2DViewCreated != null) {
          widget.onAMap2DViewCreated!(controller);
        }
      }));

    }, onError: (dynamic e) {
      if (kDebugMode) {
        print('初始化错误：$e');
      }
    });
  }

  @override
  void dispose() {
    _aMap.destroy();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _divId = DateTime.now().toIso8601String();
    /// 先创建div并注册
    // ignore: undefined_prefixed_name,avoid_dynamic_calls
    ui.platformViewRegistry.registerViewFactory(_divId, (int viewId) {
      _element = DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.margin = '0';

      return _element;
    });
    SchedulerBinding.instance.addPostFrameCallback((_) {
      /// 创建地图
      _onPlatformViewCreated();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: _divId,
    );
  }
}
