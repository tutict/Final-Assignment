import 'package:flutter/material.dart';
import 'package:final_assignment_front/config/mapjs/amap_2d_interface_controller.dart';

import 'amap_2d_view_web_state.dart'
if (dart.library.html) 'web/amap_2d_view_web_state.dart'
if (dart.library.io) 'mobile/amap_2d_view_web_state.dart';

import '../map/poi_search_model.dart';


typedef AMap2DViewCreatedCallback = void Function(AMap2DController controller);

class AMap2DView extends StatefulWidget {

  const AMap2DView({
    super.key,
    this.isPoiSearch = true,
    this.onPoiSearched,
    this.onAMap2DViewCreated,
  });

  final bool isPoiSearch;
  final AMap2DViewCreatedCallback? onAMap2DViewCreated;
  final Function(List<PoiSearch>)? onPoiSearched;

  @override
  AMap2DViewState createState() => AMap2DViewState();
}