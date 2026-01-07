import 'dart:async';
import 'dart:ui';
import 'package:final_assignment_front/features/dashboard/views/manager/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/user/user_dashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Attempt to find either DashboardController or UserDashboardController
  DashboardController? _dashboardController;
  UserDashboardController? _userDashboardController;

  @override
  void initState() {
    super.initState();
    // Initialize the appropriate controller
    try {
      _dashboardController = Get.find<DashboardController>();
    } catch (_) {
      try {
        _userDashboardController = Get.find<UserDashboardController>();
      } catch (_) {
        debugPrint('No DashboardController or UserDashboardController found');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return CupertinoPageScaffold(
      backgroundColor: isLight
          ? CupertinoColors.white.withValues(alpha: 0.9)
          : Colors.black.withValues(alpha: 0.4),
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '哈尔滨交通地图',
          style: TextStyle(
            color: isLight ? CupertinoColors.black : CupertinoColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            debugPrint('Back button tapped');
            if (_dashboardController != null) {
              _dashboardController!.exitSidebarContent();
            } else if (_userDashboardController != null) {
              _userDashboardController!.exitSidebarContent();
            } else {
              Get.back();
            }
          },
          child: const Icon(CupertinoIcons.back),
        ),
        backgroundColor:
            isLight ? CupertinoColors.systemGrey5 : CupertinoColors.systemGrey,
        brightness: isLight ? Brightness.light : Brightness.dark,
      ),
      child: SafeArea(
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(45.803775, 126.534967), // 哈尔滨经纬度
            initialZoom: 12.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.de/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: '交通违法行为处理管理系统',
              tileProvider: CustomNetworkTileProvider(),
              errorTileCallback: (tile, exception, stackTrace) {
                debugPrint(
                    "Tile failed to load: $tile, Error: $exception, StackTrace: $stackTrace");
              },
              errorImage: const NetworkImage(
                  'https://via.placeholder.com/256x256.png?text=Map+Error'),
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => debugPrint('Tapped OSM attribution'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 自定义 NetworkTileProvider，支持重试和超时
class CustomNetworkTileProvider extends TileProvider {
  @override
  ImageProvider<Object> getImage(
      TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return _RetryNetworkImage(
      url: url,
      retryCount: 3,
      maxTimeout: const Duration(seconds: 15),
    );
  }
}

// 自定义 NetworkImage，支持重试和超时
class _RetryNetworkImage extends ImageProvider<_RetryNetworkImage> {
  final String url;
  final int retryCount;
  final Duration maxTimeout;

  const _RetryNetworkImage({
    required this.url,
    this.retryCount = 3,
    this.maxTimeout = const Duration(seconds: 15),
  });

  @override
  Future<_RetryNetworkImage> obtainKey(ImageConfiguration configuration) {
    return Future.value(this);
  }

  @override
  ImageStreamCompleter loadImage(
      _RetryNetworkImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      chunkEvents: StreamController<ImageChunkEvent>().stream,
      informationCollector: () => [
        DiagnosticsProperty('URL', url),
        DiagnosticsProperty('RetryCount', retryCount),
        DiagnosticsProperty('MaxTimeout', maxTimeout),
      ],
    );
  }

  Future<Codec> _loadAsync(
      _RetryNetworkImage key, ImageDecoderCallback decode) async {
    int attempts = 0;
    while (attempts < retryCount) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(maxTimeout);
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          return decode(await ImmutableBuffer.fromUint8List(bytes));
        }
      } catch (e) {
        attempts++;
        if (attempts >= retryCount) rethrow;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    throw Exception('Failed to load tile after $retryCount attempts');
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is _RetryNetworkImage && url == other.url;
  }

  @override
  int get hashCode => url.hashCode;
}
