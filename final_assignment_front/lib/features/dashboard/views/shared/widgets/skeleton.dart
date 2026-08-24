/// 轻量 shimmer 骨架屏，无外部依赖。
///
/// 用一个移动的高光渐变扫过占位块，制造"数据即将出现"的呼吸感，
/// 替代默认的转圈 loading。亮/暗模式自动取主题表面色。
library;

import 'package:flutter/material.dart';

/// 单个会呼吸的占位块（圆角矩形）。
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  /// 为空表示撑满父级宽度。
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ShimmerMask(
        child: Container(
          decoration: BoxDecoration(
            color: _ShimmerPalette.of(context).base,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }
}

/// 整页骨架：标题行 + 两栏面板占位，模拟常见 dashboard 布局。
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({
    super.key,
    this.panels = 2,
    this.keyCount = 3,
  });

  final int panels;
  final int keyCount;

  @override
  Widget build(BuildContext context) {
    return ShimmerMask(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题区
          _row([
            _block(120, 22),
            const Spacer(),
            _block(96, 36, radius: 10),
          ]),
          const SizedBox(height: 24),
          // 指标行
          _row(
            List.generate(3, (_) => _block(double.infinity, 96)),
            spacing: 14,
          ),
          const SizedBox(height: 24),
          // 面板区
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(panels, (i) {
              return Expanded(
                child: _block(double.infinity, 220, radius: 12),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // 列表行
          _row(
            List.generate(
              keyCount,
              (_) => _block(double.infinity, 18),
            ),
            spacing: 16,
          ),
        ],
      ),
    );
  }

  Widget _row(List<Widget> children, {double spacing = 0}) {
    if (spacing == 0) {
      return Row(children: children);
    }
    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  Widget _block(double? width, double height, {double radius = 8}) {
    return ShimmerBox(width: width, height: height, radius: radius);
  }
}

/// 对子级整体施加移动高光。
class ShimmerMask extends StatefulWidget {
  const ShimmerMask({super.key, required this.child});

  final Widget child;

  @override
  State<ShimmerMask> createState() => _ShimmerMaskState();
}

class _ShimmerMaskState extends State<ShimmerMask>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pro = _ShimmerPalette.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // 高光带从左扫到右。
        final begin = Alignment(-1 + 2.6 * t, 0);
        final end = Alignment(-0.6 + 2.6 * t, 0);
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: begin,
              end: end,
              colors: [
                pro.base,
                pro.highlight,
                pro.highlight,
                pro.base,
              ],
              stops: const [0.0, 0.42, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 主题感知的 shimmer 基色/高光色。
class _ShimmerPalette {
  const _ShimmerPalette({required this.base, required this.highlight});

  final Color base;
  final Color highlight;

  static _ShimmerPalette of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _ShimmerPalette(
      base: scheme.surfaceContainerHighest.withValues(
        alpha: dark ? 0.5 : 0.62,
      ),
      highlight: scheme.surface.withValues(alpha: dark ? 0.34 : 0.9),
    );
  }
}