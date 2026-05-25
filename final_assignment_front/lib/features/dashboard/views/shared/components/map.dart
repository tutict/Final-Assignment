import 'dart:async';
import 'dart:ui';

import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
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
  static const LatLng _harbinCenter = LatLng(45.803775, 126.534967);

  final MapController _mapController = MapController();
  final Distance _distance = const Distance();

  ManagerDashboardController? _managerDashboardController;
  UserDashboardController? _userDashboardController;
  _TrafficMapPoint _selectedPoint = _trafficMapPoints.first;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ManagerDashboardController>()) {
      _managerDashboardController = Get.find<ManagerDashboardController>();
    }
    if (Get.isRegistered<UserDashboardController>()) {
      _userDashboardController = Get.find<UserDashboardController>();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = _resolveThemeData(context);
    final scheme = themeData.colorScheme;

    return Theme(
      data: themeData,
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: scheme.surface,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 860;

              return Column(
                children: [
                  _MapTopBar(
                    selectedPoint: _selectedPoint,
                    onBack: _handleBack,
                    onReset: _resetView,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 12 : 18,
                        compact ? 12 : 16,
                        compact ? 12 : 18,
                        compact ? 12 : 16,
                      ),
                      child: compact
                          ? Column(
                              children: [
                                Expanded(child: _buildMapSurface(context)),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 194,
                                  child: _buildPointPanel(context, compact),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: _buildMapSurface(context),
                                ),
                                const SizedBox(width: 14),
                                SizedBox(
                                  width: 340,
                                  child: _buildPointPanel(context, compact),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  ThemeData _resolveThemeData(BuildContext context) {
    if (_userDashboardController != null) {
      return _userDashboardController!.currentBodyTheme.value;
    }
    if (_managerDashboardController != null) {
      return _managerDashboardController!.currentBodyTheme.value;
    }
    return Theme.of(context);
  }

  Widget _buildMapSurface(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(
            alpha: dark ? 0.26 : 0.56,
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: dark ? 0.36 : 0.54),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: _harbinCenter,
                initialZoom: 12,
                minZoom: 5,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.de/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName:
                      'com.tutict.final_assignment_front.traffic_map',
                  tileProvider: CustomNetworkTileProvider(),
                  errorTileCallback: (tile, exception, stackTrace) {
                    AppLogger.debug(
                      'Map tile failed: $tile, error: $exception',
                      name: 'MapPage',
                    );
                  },
                  errorImage: const NetworkImage(
                    'https://via.placeholder.com/256x256.png?text=Map',
                  ),
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _harbinCenter,
                      radius: 6200,
                      color: scheme.primary.withValues(alpha: 0.07),
                      borderColor: scheme.primary.withValues(alpha: 0.20),
                      borderStrokeWidth: 1,
                    ),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _trafficMapPoints
                          .map((point) => point.position)
                          .toList(growable: false),
                      color: scheme.primary.withValues(alpha: 0.42),
                      strokeWidth: 3,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: _trafficMapPoints
                      .map(
                        (point) => Marker(
                          point: point.position,
                          width: 48,
                          height: 48,
                          child: _MapMarker(
                            point: point,
                            selected: point == _selectedPoint,
                            onTap: () => _selectPoint(point),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => AppLogger.debug(
                        'OpenStreetMap attribution tapped',
                        name: 'MapPage',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: _MapSearchSurface(
                selectedPoint: _selectedPoint,
                distanceLabel: _distanceLabel(_selectedPoint),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 14,
              child: _MapControls(
                onZoomIn: () => _zoomBy(1),
                onZoomOut: () => _zoomBy(-1),
                onReset: _resetView,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointPanel(BuildContext context, bool compact) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: dark ? 0.84 : 0.98),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.36 : 0.54),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: dark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.map_rounded,
                    color: scheme.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '交通地图',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '哈尔滨常用业务点位',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: dark ? 0.34 : 0.5),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              scrollDirection: compact ? Axis.horizontal : Axis.vertical,
              itemCount: _trafficMapPoints.length,
              separatorBuilder: (_, __) =>
                  SizedBox(width: compact ? 10 : 0, height: compact ? 0 : 10),
              itemBuilder: (context, index) {
                final point = _trafficMapPoints[index];
                return SizedBox(
                  width: compact ? 260 : null,
                  child: _MapPointTile(
                    point: point,
                    selected: point == _selectedPoint,
                    distanceLabel: _distanceLabel(point),
                    onTap: () => _selectPoint(point),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleBack() {
    if (_managerDashboardController != null) {
      _managerDashboardController!.exitSidebarContent();
      return;
    }
    if (_userDashboardController != null) {
      _userDashboardController!.exitSidebarContent();
      return;
    }
    Get.back<void>();
  }

  void _selectPoint(_TrafficMapPoint point) {
    setState(() => _selectedPoint = point);
    _mapController.move(point.position, 14.2);
  }

  void _resetView() {
    setState(() => _selectedPoint = _trafficMapPoints.first);
    _mapController.move(_harbinCenter, 12);
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta).clamp(5.0, 18.0).toDouble();
    _mapController.move(camera.center, nextZoom);
  }

  String _distanceLabel(_TrafficMapPoint point) {
    final meters = _distance(_harbinCenter, point.position);
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
}

class _MapTopBar extends StatelessWidget {
  const _MapTopBar({
    required this.selectedPoint,
    required this.onBack,
    required this.onReset,
  });

  final _TrafficMapPoint selectedPoint;
  final VoidCallback onBack;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: dark ? 0.92 : 0.98),
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: dark ? 0.36 : 0.52),
          ),
        ),
      ),
      child: Row(
        children: [
          Tooltip(
            message: '返回',
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '地图服务',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '当前查看：${selectedPoint.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: '回到哈尔滨视图',
            child: IconButton.filledTonal(
              onPressed: onReset,
              icon: const Icon(Icons.my_location_rounded, size: 19),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapSearchSurface extends StatelessWidget {
  const _MapSearchSurface({
    required this.selectedPoint,
    required this.distanceLabel,
  });

  final _TrafficMapPoint selectedPoint;
  final String distanceLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: dark ? 0.88 : 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.38 : 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.20 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.place_outlined, color: scheme.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedPoint.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _MapPill(label: distanceLabel),
          ],
        ),
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: dark ? 0.88 : 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.38 : 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ControlIconButton(
            icon: Icons.add_rounded,
            tooltip: '放大',
            onPressed: onZoomIn,
          ),
          _ControlDivider(color: scheme.outlineVariant),
          _ControlIconButton(
            icon: Icons.remove_rounded,
            tooltip: '缩小',
            onPressed: onZoomOut,
          ),
          _ControlDivider(color: scheme.outlineVariant),
          _ControlIconButton(
            icon: Icons.center_focus_strong_rounded,
            tooltip: '重置视图',
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
}

class _ControlIconButton extends StatelessWidget {
  const _ControlIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        splashRadius: 22,
      ),
    );
  }
}

class _ControlDivider extends StatelessWidget {
  const _ControlDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      child: Divider(
        height: 1,
        thickness: 1,
        color: color.withValues(alpha: 0.48),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.point,
    required this.selected,
    required this.onTap,
  });

  final _TrafficMapPoint point;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : point.color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: selected ? 46 : 40,
        height: selected ? 46 : 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: selected ? 3 : 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.36),
              blurRadius: selected ? 18 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(point.icon, color: Colors.white, size: selected ? 23 : 20),
      ),
    );
  }
}

class _MapPointTile extends StatelessWidget {
  const _MapPointTile({
    required this.point,
    required this.selected,
    required this.distanceLabel,
    required this.onTap,
  });

  final _TrafficMapPoint point;
  final bool selected;
  final String distanceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final color = selected ? scheme.primary : point.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: dark ? 0.20 : 0.10)
                : scheme.surfaceContainerHighest.withValues(
                    alpha: dark ? 0.28 : 0.52,
                  ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: dark ? 0.56 : 0.42)
                  : scheme.outlineVariant.withValues(
                      alpha: dark ? 0.28 : 0.42,
                    ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: dark ? 0.28 : 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(point.icon, color: color, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            point.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _MapPill(label: distanceLabel),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      point.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPill extends StatelessWidget {
  const _MapPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _TrafficMapPoint {
  const _TrafficMapPoint({
    required this.title,
    required this.description,
    required this.position,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final LatLng position;
  final IconData icon;
  final Color color;
}

const List<_TrafficMapPoint> _trafficMapPoints = [
  _TrafficMapPoint(
    title: '交通管理服务中心',
    description: '违法处理、业务咨询和材料核验的综合服务点。',
    position: LatLng(45.803775, 126.534967),
    icon: Icons.account_balance_rounded,
    color: Color(0xFF2F7DD6),
  ),
  _TrafficMapPoint(
    title: '违法处理窗口',
    description: '适合办理违法查询、处罚确认和申诉材料提交。',
    position: LatLng(45.77525, 126.62374),
    icon: Icons.gavel_rounded,
    color: Color(0xFFE0A13A),
  ),
  _TrafficMapPoint(
    title: '车辆登记窗口',
    description: '办理车辆登记、档案维护和信息核验业务。',
    position: LatLng(45.70748, 126.59102),
    icon: Icons.directions_car_filled_rounded,
    color: Color(0xFF24A39C),
  ),
  _TrafficMapPoint(
    title: '事故快处服务点',
    description: '用于事故快处指引、证据提交和进度咨询。',
    position: LatLng(45.81173, 126.55989),
    icon: Icons.health_and_safety_rounded,
    color: Color(0xFF8C74E8),
  ),
];

class CustomNetworkTileProvider extends TileProvider {
  @override
  ImageProvider<Object> getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) {
    final url = getTileUrl(coordinates, options);
    return _RetryNetworkImage(
      url: url,
      retryCount: 3,
      maxTimeout: const Duration(seconds: 15),
    );
  }
}

class _RetryNetworkImage extends ImageProvider<_RetryNetworkImage> {
  const _RetryNetworkImage({
    required this.url,
    this.retryCount = 3,
    this.maxTimeout = const Duration(seconds: 15),
  });

  final String url;
  final int retryCount;
  final Duration maxTimeout;

  @override
  Future<_RetryNetworkImage> obtainKey(ImageConfiguration configuration) {
    return Future.value(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _RetryNetworkImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1,
      chunkEvents: StreamController<ImageChunkEvent>().stream,
      informationCollector: () => [
        DiagnosticsProperty('URL', url),
        DiagnosticsProperty('RetryCount', retryCount),
        DiagnosticsProperty('MaxTimeout', maxTimeout),
      ],
    );
  }

  Future<Codec> _loadAsync(
    _RetryNetworkImage key,
    ImageDecoderCallback decode,
  ) async {
    var attempts = 0;
    while (attempts < retryCount) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(maxTimeout);
        if (response.statusCode == 200) {
          return decode(
            await ImmutableBuffer.fromUint8List(response.bodyBytes),
          );
        }
      } catch (error) {
        attempts++;
        if (attempts >= retryCount) rethrow;
        AppLogger.debug(
          'Retrying map tile: $url, attempt: $attempts, error: $error',
          name: 'MapPage',
        );
        await Future<void>.delayed(const Duration(milliseconds: 800));
      }
    }
    throw Exception('Failed to load map tile after $retryCount attempts');
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is _RetryNetworkImage && url == other.url;
  }

  @override
  int get hashCode => url.hashCode;
}
