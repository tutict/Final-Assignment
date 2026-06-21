import 'package:flutter/material.dart';

enum ResponsiveBreakpoint { mobile, tablet, desktop }

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    required this.mobileBuilder,
    required this.tabletBuilder,
    required this.desktopBuilder,
    super.key,
  });

  static const double mobileMaxWidth = 700;
  static const double desktopMinWidth = 1100;

  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
  ) mobileBuilder;

  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
  ) tabletBuilder;

  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
  ) desktopBuilder;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMaxWidth;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width < desktopMinWidth && width >= mobileMaxWidth;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopMinWidth;

  static ResponsiveBreakpoint breakpointFor(double width) {
    if (width >= desktopMinWidth) return ResponsiveBreakpoint.desktop;
    if (width >= mobileMaxWidth) return ResponsiveBreakpoint.tablet;
    return ResponsiveBreakpoint.mobile;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = breakpointFor(constraints.maxWidth);
        final child = switch (breakpoint) {
          ResponsiveBreakpoint.desktop => desktopBuilder(context, constraints),
          ResponsiveBreakpoint.tablet => tabletBuilder(context, constraints),
          ResponsiveBreakpoint.mobile => mobileBuilder(context, constraints),
        };

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: KeyedSubtree(
            key: ValueKey(breakpoint),
            child: child,
          ),
        );
      },
    );
  }
}
