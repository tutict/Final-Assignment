/// 轻量级动效工具集。
///
/// 复用这些组件可以让页面在保持既有视觉体系的前提下获得一致的
/// 入场 / 数字滚动 / hover 反馈，避免每个页面各自手写动画。
library;

import 'package:flutter/material.dart';

/// 统一的入场动画：淡入 + 轻微上移，支持可选的级联延迟。
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 360),
    this.offset = const Offset(0, 0.03),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      // 级联延迟：延迟结束后再开始入场，期间保持完全透明且不上移。
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final curveValue = widget.curve.transform(_controller.value);
        return Opacity(
          opacity: curveValue,
          child: Transform.translate(
            offset: Offset(
              widget.offset.dx * (1 - curveValue),
              widget.offset.dy * (1 - curveValue),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// 数字滚动动画：值进入时从 0（或上一个值）滚动到目标值。
///
/// 仅当 [value] 是"带可选千分位逗号 / 可选正负号 / 可选单位后缀"的数字时
/// 才启用滚动；否则（如日期、编号）原样展示，绝对安全。
class MetricCountUp extends StatelessWidget {
  const MetricCountUp({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
  });

  final String value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final parsed = _NumericToken.parse(value);
    if (parsed == null) {
      return Text(value, style: style);
    }
    return _AnimatedNumber(
      token: parsed,
      style: style,
      duration: duration,
      curve: curve,
    );
  }
}

class _AnimatedNumber extends StatelessWidget {
  const _AnimatedNumber({
    required this.token,
    required this.style,
    required this.duration,
    required this.curve,
  });

  final _NumericToken token;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: token.number),
      duration: duration,
      curve: curve,
      builder: (context, value, _) {
        final text = token.format(value);
        return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: style);
      },
    );
  }
}

/// 从字符串中安全解析出一个数值 + 可还原的前后缀/小数位信息。
class _NumericToken {
  const _NumericToken({
    required this.prefix,
    required this.number,
    required this.decimals,
    required this.thousands,
    required this.suffix,
  });

  final String prefix;
  final double number;
  final int decimals;
  final bool thousands;
  final String suffix;

  static _NumericToken? parse(String raw) {
    if (raw.isEmpty) return null;
    final match = RegExp(r'^([^\d.\-]*)(-?\d+(?:,\d{3})*(?:\.\d+)?)(.*)$')
        .firstMatch(raw);
    if (match == null) return null;

    final prefix = match.group(1) ?? '';
    final numberStr = match.group(2)!;
    final suffix = match.group(3) ?? '';

    final hasThousands = numberStr.contains(',');
    final cleaned = numberStr.replaceAll(',', '');
    final number = double.tryParse(cleaned);
    if (number == null) return null;

    final decimals = cleaned.contains('.')
        ? cleaned.split('.')[1].length
        : 0;

    return _NumericToken(
      prefix: prefix,
      number: number,
      decimals: decimals,
      thousands: hasThousands,
      suffix: suffix,
    );
  }

  String format(double value) {
    // 用 toStringAsFixed 统一小数位，再把整部分做千分位。
    final fixed = value.toStringAsFixed(decimals);
    final isNeg = fixed.startsWith('-');
    final unsigned = isNeg ? fixed.substring(1) : fixed;
    final dot = unsigned.indexOf('.');
    var intPart = dot < 0 ? unsigned : unsigned.substring(0, dot);
    final fracPart = dot < 0 ? '' : unsigned.substring(dot);
    if (thousands) intPart = _groupThousands(intPart);
    return '$prefix${isNeg ? '-' : ''}$intPart$fracPart$suffix';
  }

  static String _groupThousands(String s) {
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final remaining = s.length - i;
      if (i > 0 && remaining % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

/// Hover 抬升：鼠标进入时轻微放大 + 阴影加重 + 背景微变，离开时还原。
///
/// 桌面端可感知的最直接"质感"来源；触屏上自动退化为静态。
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.scale = 1.006,
    this.duration = const Duration(milliseconds: 180),
  });

  final Widget child;
  final double scale;
  final Duration duration;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}