import 'package:flutter/material.dart';

import 'motion.dart';

class DashboardBackdrop extends StatelessWidget {
  const DashboardBackdrop({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.scaffoldBackgroundColor,
            dark
                ? scheme.surfaceContainer.withValues(alpha: 0.76)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.58),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _DashboardBackdropPainter(
          lineColor:
              scheme.outlineVariant.withValues(alpha: dark ? 0.14 : 0.22),
          bandColor: scheme.primary.withValues(alpha: dark ? 0.10 : 0.08),
        ),
        child: child,
      ),
    );
  }
}

class DashboardPanel extends StatefulWidget {
  const DashboardPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.height,
    this.hoverable = false,
    this.hoverRadius = 14,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? height;

  /// 是否启用 hover 抬升反馈（桌面端）。触屏无感，默认关闭以保持纯净。
  final bool hoverable;

  /// hover 时圆角提升到的值，配合阴影抬升更显层次。
  final double hoverRadius;

  /// 可选点击回调（非 null 时启用 InkWell 涟漪）。
  final VoidCallback? onTap;

  @override
  State<DashboardPanel> createState() => _DashboardPanelState();
}

class _DashboardPanelState extends State<DashboardPanel> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final elevated = widget.hoverable && _hovered;

    final decoration = BoxDecoration(
      color: scheme.surface.withValues(alpha: dark ? 0.92 : 0.96),
      borderRadius: BorderRadius.circular(elevated ? widget.hoverRadius : 8),
      border: Border.all(
        color: elevated
            ? scheme.primary.withValues(alpha: dark ? 0.5 : 0.6)
            : scheme.outlineVariant.withValues(alpha: dark ? 0.45 : 0.58),
      ),
      boxShadow: elevated
          ? [
              // 抬升时投影更强调，营造"浮起"。
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: dark ? 0.34 : 0.16),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: dark ? 0.22 : 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          : [
              // 双层软阴影：近处贴身 + 远处柔和，比单层更有质感。
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: dark ? 0.16 : 0.07),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: dark ? 0.12 : 0.05),
                blurRadius: 34,
                offset: const Offset(0, 14),
              ),
            ],
    );

    Widget child = widget.child;
    if (widget.onTap != null || widget.hoverable) {
      child = MouseRegion(
        onEnter: widget.hoverable
            ? (_) => setState(() => _hovered = true)
            : null,
        onExit: widget.hoverable
            ? (_) => setState(() => _hovered = false)
            : null,
        child: AnimatedScale(
          scale: elevated ? 1.008 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: child,
        ),
      );
    }

    final container = Container(
      height: widget.height,
      margin: widget.margin,
      padding: widget.padding,
      decoration: decoration,
      child: child,
    );

    if (widget.onTap != null) {
      return InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(elevated ? widget.hoverRadius : 8),
        splashColor: scheme.primary.withValues(alpha: 0.06),
        highlightColor: scheme.primary.withValues(alpha: 0.04),
        child: container,
      );
    }
    return container;
  }
}

class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  letterSpacing: 0,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class DashboardMetricTile extends StatelessWidget {
  const DashboardMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DashboardPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: scheme.onPrimaryContainer, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                MetricCountUp(
                  value: value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBackdropPainter extends CustomPainter {
  const _DashboardBackdropPainter({
    required this.lineColor,
    required this.bandColor,
  });

  final Color lineColor;
  final Color bandColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final bandPaint = Paint()
      ..color = bandColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28;

    for (double y = -size.height; y < size.height * 1.6; y += 96) {
      canvas.drawLine(
        Offset(-24, y),
        Offset(size.width + 24, y + size.width * 0.16),
        linePaint,
      );
    }

    final path = Path()
      ..moveTo(-32, size.height * 0.78)
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.66,
        size.width * 0.48,
        size.height * 0.94,
        size.width + 32,
        size.height * 0.74,
      );
    canvas.drawPath(path, bandPaint);
  }

  @override
  bool shouldRepaint(covariant _DashboardBackdropPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.bandColor != bandColor;
  }
}
