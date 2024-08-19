import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

class UserToolsCard extends StatelessWidget {
  const UserToolsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onPressed,
    this.onPressedSecond,
    this.onPressedThird,
    this.onPressedFourth,
    this.onPressedFifth,
    this.onPressedSixth,
    this.onPressedSeventh,
    this.onPressedEighth,
    this.onPressedNinth,
    this.onPressedTenth,
  });

  final String title;
  final IconData icon;
  final Function() onPressed;
  final Function()? onPressedSecond;
  final Function()? onPressedThird;
  final Function()? onPressedFourth;
  final Function()? onPressedFifth;
  final Function()? onPressedSixth;
  final Function()? onPressedSeventh;
  final Function()? onPressedEighth;
  final Function()? onPressedNinth;
  final Function()? onPressedTenth;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Icon and title section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  size: 48.0,
                  color: Colors.lightBlueAccent,
                ),
                const SizedBox(height: 8.0),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _buildButton(
                activeIcon: EvaIcons.arrowForward,
                icon: EvaIcons.arrowForwardOutline,
                context,
                onPressed,
                'Main Action',
              ),
              if (onPressedSecond != null)
                _buildButton(
                  activeIcon: EvaIcons.arrowForward,
                  icon: EvaIcons.arrowForwardOutline,
                  context,
                  onPressedSecond,
                  'Secondary Action',
                ),
              if (onPressedThird != null)
                _buildButton(
                  activeIcon: EvaIcons.arrowForward,
                  icon: EvaIcons.arrowForwardOutline,
                  context,
                  onPressedThird,
                  'Third Action',
                ),
              if (onPressedFourth != null)
                _buildButton(
                  activeIcon: EvaIcons.arrowForward,
                  icon: EvaIcons.arrowForwardOutline,
                  context,
                  onPressedFourth,
                  'Fourth Action',
                ),
              if (onPressedFifth != null)
                _buildButton(
                  activeIcon: EvaIcons.arrowForward,
                  icon: EvaIcons.arrowForwardOutline,
                  context,
                  onPressedFifth,
                  'Fifth Action',
                ),
             if (onPressedSixth != null)
                _buildButton(
                  activeIcon: EvaIcons.arrowForward,
                  icon: EvaIcons.arrowForwardOutline,
                  context,
                  onPressedSixth,
                  'Sixth Action',
                ),
              if (onPressedSeventh != null)
                _buildButton(
                  activeIcon: EvaIcons.arrowForward,
                  icon: EvaIcons.arrowForwardOutline,
                  context,
                  onPressedSeventh,
                  'Seventh Action',
                ),
              if (onPressedEighth != null)
                _buildButton(
                  activeIcon: EvaIcons.arrowForward,
                  icon: EvaIcons.arrowForwardOutline,
                  context,
                  onPressedEighth,
                  'Eighth Action',
                ),
              if (onPressedNinth != null)
                _buildButton(
                  activeIcon: EvaIcons.arrowForward,
                  icon: EvaIcons.arrowForwardOutline,
                  context,
                  onPressedNinth,
                  'Ninth Action',
                ),
              if (onPressedTenth != null)
                _buildButton(
                  activeIcon: EvaIcons.arrowForward,
                  icon: EvaIcons.arrowForwardOutline,
                  context,
                  onPressedTenth,
                  'Tenth Action',
                )
            ],
          ),
          const SizedBox(height: 10.0),
        ],
      ),
    );
  }

  // Helper method to build buttons
  Widget _buildButton(BuildContext context, Function()? onTap, String text, {required IconData activeIcon, required IconData icon}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: const TextStyle(color: Colors.blue),
        ),
      ),
    );
  }
}