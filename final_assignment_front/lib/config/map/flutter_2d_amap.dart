import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// 导出二维地图视图组件
export '../mapjs/amap_2d_view.dart';

// 导出二维地图接口控制器
export '../mapjs/amap_2d_interface_controller.dart';

// 导出POI搜索模型
export './poi_search_model.dart';

// Flutter 2D高德地图插件类
class Flutter2dAMap {
  // 创建一个方法通道，用于和原生代码通信
  static const MethodChannel _channel =
      MethodChannel('plugins.weilu/flutter_2d_amap_');

  // 高德地图Web端密钥
  static String _webKey = '';

  // 获取Web端密钥
  static String get webKey => _webKey;

  // 设置API密钥
  static Future<bool?> setApiKey(
      {String iOSKey = '', String webKey = ''}) async {
    // 如果是Web端，直接设置Web密钥
    if (kIsWeb) {
      _webKey = webKey;
    } else {
      // 如果是iOS端，通过方法通道调用原生代码设置密钥
      if (Platform.isIOS) {
        return _channel.invokeMethod<bool>('setKey', iOSKey);
      }
    }
    // 默认返回成功
    return Future.value(true);
  }

  // 更新用户对隐私政策的同意状态，需在地图初始化前完成
  static Future<void> updatePrivacy(bool isAgree) async {
    // 如果是Web端，无需操作
    if (kIsWeb) {
    } else {
      // 如果是iOS或Android端，通过方法通道调用原生代码更新隐私状态
      if (Platform.isIOS || Platform.isAndroid) {
        await _channel.invokeMethod<bool>('updatePrivacy', isAgree.toString());
      }
    }
  }
}
