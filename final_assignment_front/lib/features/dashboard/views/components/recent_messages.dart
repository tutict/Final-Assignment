part of '../screens/manager_dashboard_screen.dart';

class _RecentMessages extends StatelessWidget {
  const _RecentMessages({
    required this.onPressedMore,
  });

  final Function() onPressedMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(EvaIcons.messageCircle, color: Theme.of(context).primaryColor),
        const SizedBox(width: 10),
        Text(
          "来自其他管理员的消息",
          style: TextStyle(color: Theme.of(context).primaryColor).useSystemChineseFont(),
        ),
        const Spacer(),
        IconButton(
          onPressed: onPressedMore,
          icon: const Icon(EvaIcons.moreVertical),
          tooltip: "more",
        )
      ],
    );
  }
}
