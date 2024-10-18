import 'package:flutter/material.dart';

/// 用于构建响应式UI的组件。
///
/// 该组件根据设备屏幕大小使用不同的构建器函数来返回不同的UI结构。
/// 主要用于处理移动设备、平板电脑和桌面屏幕的响应式布局。
class ResponsiveBuilder extends StatelessWidget {
  /// ResponsiveBuilder 的构造函数。
  const ResponsiveBuilder({
    required this.mobileBuilder,
    required this.tabletBuilder,
    required this.desktopBuilder,
    super.key,
  });

  // 移动设备屏幕的构建器函数。
  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
  ) mobileBuilder;

  // 平板电脑屏幕的构建器函数。
  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
  ) tabletBuilder;

  // 桌面屏幕的构建器函数。
  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
  ) desktopBuilder;

  /// 判断当前设备是否为移动设备屏幕。
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  /// 判断当前设备是否为平板电脑屏幕。
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width < 1250 &&
      MediaQuery.of(context).size.width >= 650;

  /// 判断当前设备是否为桌面屏幕。
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1250;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据屏幕宽度选择合适的构建器函数。
        if (constraints.maxWidth >= 1250) {
          return desktopBuilder(context, constraints);
        } else if (constraints.maxWidth >= 650) {
          return tabletBuilder(context, constraints);
        } else {
          return mobileBuilder(context, constraints);
        }
      },
    );
  }
}
