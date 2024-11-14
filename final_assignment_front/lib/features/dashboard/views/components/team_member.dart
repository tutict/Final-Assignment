part of '../manager_screens/manager_dashboard_screen.dart';

class _TeamMember extends StatelessWidget {
  const _TeamMember({
    required this.totalMember,
    required this.onPressedAdd,
  });

  final int totalMember;
  final Function() onPressedAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: kFontColorPallets[0],
            ),
            children: [
              const TextSpan(text: "其他管理员"),
              TextSpan(
                text: "($totalMember)",
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: kFontColorPallets[2],
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onPressedAdd,
          icon: const Icon(EvaIcons.plus),
          tooltip: "add member",
        )
      ],
    );
  }
}
