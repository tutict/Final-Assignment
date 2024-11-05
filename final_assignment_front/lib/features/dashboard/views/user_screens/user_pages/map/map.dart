import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('线下网点'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Get.back(); // Using Get.back() for consistency if using GetX
          },
        ),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
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
            child: Material(
              elevation: 5.0,
              borderRadius: BorderRadius.circular(10.0),
              child: TextField(
                onSubmitted: (query) {
                  if (query.isNotEmpty) {
                    _mapController.search(query);
                  }
                },
                decoration: const InputDecoration(
                  hintText: "搜索位置",
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
                ),
              ),
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
                FloatingActionButton(
                  onPressed: () {
                    // 定位到当前用户位置的功能
                    _mapController.location();
                  },
                  child: const Icon(Icons.my_location),
                ),
                FloatingActionButton(
                  onPressed: () {
                    // 可以添加其他功能按钮
                    // 示例：切换地图类型或添加标记
                  },
                  child: const Icon(Icons.layers),
                ),
              ],
            ),
          ),
          // 地图上悬浮的中间组件
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 20,
            left: MediaQuery.of(context).size.width / 2 - 20,
            child: const Icon(
              Icons.location_on,
              size: 40,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
