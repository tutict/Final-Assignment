import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/shared_components/search_field.dart';
import 'package:final_assignment_front/shared_components/today_text.dart';
import 'package:flutter/material.dart';

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
                width: 1.0, // Border width
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
