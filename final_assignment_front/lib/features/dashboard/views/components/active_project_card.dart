part of '../manager_screens/manager_dashboard_screen.dart';

class _ActiveProjectCard extends StatelessWidget {
  const _ActiveProjectCard({
    required this.child,
    required this.onPressedSeeAll,
    this.title = "图表呈现", // Default title, customizable
  });

  final Widget child;
  final Function() onPressedSeeAll;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      // Subtle shadow for depth
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      margin: const EdgeInsets.symmetric(vertical: kSpacing / 2),
      color: theme.cardColor,
      // Theme-aware card background
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kBorderRadius),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceVariant.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
                color: theme.colorScheme.onSurface.withOpacity(
                    0.2), // Theme-aware divider
              ),
              const SizedBox(height: kSpacing / 2),
              // Child widget (e.g., chart)
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface, // Theme-aware text color
      )?.useSystemChineseFont(),
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
          color: theme.colorScheme.primary.withOpacity(0.1),
          // Theme-aware button background
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "详情",
              style: TextStyle(
                color: theme.colorScheme.primary, // Theme-aware text color
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ).useSystemChineseFont(),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: theme.colorScheme.primary, // Theme-aware icon color
            ),
          ],
        ),
      ),
    );
  }
}