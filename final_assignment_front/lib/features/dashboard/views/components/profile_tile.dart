import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/features/dashboard/models/profile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilTile extends StatelessWidget {
  const ProfilTile({
    super.key,
    required this.data,
    required this.onPressedNotification,
  });

  final Profile data;
  final VoidCallback onPressedNotification;

  Future<String> _getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    final driverName = prefs.getString('driverName');
    return driverName ?? data.name; // Fallback to Profile name if not found
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    // Theme-based colors
    final Color backgroundColor =
        isLight ? Colors.white : Theme.of(context).cardColor.withOpacity(0.9);
    final Color shadowColor = Colors.black.withOpacity(isLight ? 0.1 : 0.2);
    final Color defaultTextColor = isLight ? Colors.black87 : Colors.white;
    final Color subtitleTextColor =
        isLight ? Colors.grey.shade600 : Colors.white70;
    final Color iconColor = isLight ? Colors.grey.shade700 : Colors.white70;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: const Offset(0, 3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: FutureBuilder<String>(
        future: _getDisplayName(),
        builder: (context, snapshot) {
          String displayName = data.name; // Default
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            displayName = snapshot.data!;
            debugPrint('Display name set to: $displayName');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            debugPrint('Error fetching display name: ${snapshot.error}');
          }

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            leading: GestureDetector(
              onTap: () {
                debugPrint("Avatar clicked for $displayName");
              },
              child: CircleAvatar(
                backgroundImage: data.photo,
                radius: 28,
                backgroundColor:
                    isLight ? Colors.grey.shade200 : Colors.grey.shade800,
                child: data.photo == null
                    ? Icon(Icons.person, size: 28, color: iconColor)
                    : null,
              ),
            ),
            title: Text(
              displayName,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: defaultTextColor,
                    letterSpacing: 0.5,
                  )
                  .useSystemChineseFont(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              data.email,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(
                    fontSize: 16,
                    color: subtitleTextColor,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  )
                  .useSystemChineseFont(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              onPressed: onPressedNotification,
              icon: Icon(
                EvaIcons.bellOutline,
                size: 26,
                color: iconColor,
              ),
              tooltip: "通知",
              splashRadius: 26,
              splashColor: Theme.of(context).primaryColor.withOpacity(0.3),
              highlightColor: Colors.transparent,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onTap: () {
              debugPrint("Profile tile tapped for $displayName");
            },
          );
        },
      ),
    );
  }
}
