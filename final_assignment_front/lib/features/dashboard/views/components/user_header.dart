part of '../user_screens/user_dashboard.dart';

class UserHeader extends StatelessWidget {
  const UserHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const TodayText(),
        const SizedBox(width: kSpacing),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey, // Border color
              ),
              borderRadius:
                  BorderRadius.circular(8.0), // Optional: Rounded corners
            ),
            child: SearchField(), // Your SearchField widget
          ),
        ),
      ],
    );
  }
}
