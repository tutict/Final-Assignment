part of '../manager_dashboard_screen.dart';

class _TeamMember extends StatelessWidget {
  const _TeamMember({
    required this.totalMember,
    required this.onPressedAdd,
  });

  final int totalMember;
  final Function() onPressedAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: TextSpan(
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: scheme.onSurface,
              letterSpacing: 0,
            ),
            children: [
              const TextSpan(text: '其他管理员'),
              TextSpan(
                text: '($totalMember)',
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: onPressedAdd,
          icon: Icon(
            EvaIcons.plus,
            color: scheme.onSurface,
          ),
          tooltip: '添加成员',
          iconSize: 24,
          padding: const EdgeInsets.all(8),
        ),
      ],
    );
  }
}
