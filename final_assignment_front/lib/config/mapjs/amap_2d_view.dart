import 'package:flutter/material.dart';
import 'package:final_assignment_front/config/mapjs/amap_2d_interface_controller.dart';

// 根据不同的平台加载不同的状态类
import 'amap_2d_view_web_state.dart'
    if (dart.library.html) 'web/amap_2d_view_web_state.dart'
    if (dart.library.io) 'mobile/amap_2d_view_web_state.dart';

import '../map/poi_search_model.dart';

// 定义回调类型，用于在地图视图创建时通知
typedef AMap2DViewCreatedCallback = void Function(AMap2DController controller);

// AMap2DView类用于显示二维地图视图
class AMap2DView extends StatefulWidget {
  // 是否进行兴趣点搜索，默认为true
  final bool isPoiSearch;

  // 回调函数，当兴趣点搜索完成时调用
  final Function(List<PoiSearch>)? onPoiSearched;

  // 回调函数，当地图视图创建时调用
  final AMap2DViewCreatedCallback? onAMap2DViewCreated;

  // 构造函数
  const AMap2DView({
    super.key,
    this.isPoiSearch = true,
    this.onPoiSearched,
    this.onAMap2DViewCreated,
  });

  // 创建状态对象
  @override
  AMap2DViewState createState() => AMap2DViewState();
}
