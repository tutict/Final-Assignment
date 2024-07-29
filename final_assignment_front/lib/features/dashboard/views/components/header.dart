part of '../screens/manager_dashboard_screen.dart';

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const TodayText(),
        const SizedBox(width: kSpacing),
        Expanded(child: SearchField()),
      ],
    );
  }
}
