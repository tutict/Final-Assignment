import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('哈尔滨地图'),
      ),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(45.803775, 126.534967), // 哈尔滨的经纬度
          initialZoom: 12.0, // 设置缩放级别
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            // 使用OpenStreetMap瓦片
            userAgentPackageName: '交通违法行为处理管理系统', // 添加您的应用标识符
          ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () =>
                    Uri.parse('https://openstreetmap.org/copyright'), // 外部链接
              ),
            ],
          ),
        ],
      ),
    );
  }
}
