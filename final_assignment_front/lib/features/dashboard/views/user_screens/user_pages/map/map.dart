import 'package:flutter/cupertino.dart';
import 'package:get/get.dart'; // Assuming you are using GetX for navigation
import 'package:final_assignment_front/config/map/flutter_2d_amap.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late AMap2DController _mapController;
  List<PoiSearch> _poiSearchResults = [];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('线下网点'),
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: const Icon(CupertinoIcons.back),
        ),
        backgroundColor: CupertinoColors.systemBlue,
        brightness: Brightness.dark,
      ),
      child: Stack(
        children: [
          // 地图视图
          AMap2DView(
            onAMap2DViewCreated: (controller) {
              _mapController = controller;
            },
            onPoiSearched: (results) {
              setState(() {
                _poiSearchResults = results;
              });
            },
          ),
          // 顶部搜索框
          Positioned(
            top: 40.0,
            left: 20.0,
            right: 20.0,
            child: CupertinoSearchTextField(
              onSubmitted: (query) {
                if (query.isNotEmpty) {
                  _mapController.search(query);
                }
              },
              padding: const EdgeInsets.all(12.0),
            ),
          ),
          // 底部按钮
          Positioned(
            bottom: 50.0,
            left: 20.0,
            right: 20.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.all(0),
                  child: const Icon(
                    CupertinoIcons.location_fill,
                    size: 30.0,
                    color: CupertinoColors.systemBlue,
                  ),
                  onPressed: () {
                    // 定位到当前用户位置的功能
                    _mapController.location();
                  },
                ),
                CupertinoButton(
                  padding: const EdgeInsets.all(0),
                  child: const Icon(
                    CupertinoIcons.layers_alt_fill,
                    size: 30.0,
                    color: CupertinoColors.systemBlue,
                  ),
                  onPressed: () {
                    // 可以添加其他功能按钮
                    // 示例：切换地图类型或添加标记
                  },
                ),
              ],
            ),
          ),
          // 地图上悬浮的中间组件
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 20,
            left: MediaQuery.of(context).size.width / 2 - 20,
            child: const Icon(
              CupertinoIcons.location_solid,
              size: 40,
              color: CupertinoColors.systemRed,
            ),
          ),
        ],
      ),
    );
  }
}
