import 'package:flutter/material.dart';

// Define constants
const double kSpacing = 16.0;
const double kBorderRadius = 8.0;

class ActiveProjectCard extends StatelessWidget {
  const ActiveProjectCard({
    super.key,
    required this.child,
    required this.onPressedSeeAll,
    this.title = "图表呈现",
  });

  final Widget child;
  final Function() onPressedSeeAll;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: kSpacing / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kBorderRadius),
        gradient: LinearGradient(
          colors: [
            scheme.surface,
            scheme.surfaceContainerHighest.withValues(alpha: dark ? 0.7 : 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.45 : 0.58),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: dark ? 0.18 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(kSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTitle(context),
                _buildSeeAllButton(context),
              ],
            ),
            Divider(
              thickness: 1,
              height: kSpacing * 1.5,
              color: scheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: kSpacing / 2),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.onSurface,
        letterSpacing: 0,
      ),
    );
  }

  Widget _buildSeeAllButton(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPressedSeeAll,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "详情",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
