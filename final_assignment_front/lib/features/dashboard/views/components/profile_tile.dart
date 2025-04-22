import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/features/dashboard/models/profile.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilTile extends StatelessWidget {
  ProfilTile({
    super.key,
    required this.data,
    required this.onPressedNotification,
  });

  final Profile data;
  final VoidCallback onPressedNotification;
  final UserDashboardController _userController =
      Get.find<UserDashboardController>();
  final DashboardController _adminController = Get.find<DashboardController>();

  Future<String> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userRole') ?? 'USER';
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final Color backgroundColor =
        isLight ? Colors.white : Theme.of(context).cardColor.withOpacity(0.9);
    final Color shadowColor = Colors.black.withOpacity(isLight ? 0.1 : 0.2);
    final Color defaultTextColor = isLight ? Colors.black87 : Colors.white;
    final Color subtitleTextColor =
        isLight ? Colors.grey.shade600 : Colors.white70;
    final Color iconColor = isLight ? Colors.grey.shade700 : Colors.white70;

    return FutureBuilder<String>(
      future: _getUserRole(),
      builder: (context, roleSnapshot) {
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final String userRole = roleSnapshot.data ?? 'USER';

        return Obx(() {
          String displayName;
          String displayEmail;
          String displayPost;

          if (userRole == 'USER') {
            displayName = _userController.currentDriverName.value.isNotEmpty
                ? _userController.currentDriverName.value
                : data.name;
            displayEmail = _userController.currentEmail.value.isNotEmpty
                ? _userController.currentEmail.value
                : data.email;
            displayPost = '欢迎使用交通违法行为处理管理系统用户端';
          } else {
            displayName = _adminController.currentDriverName.value.isNotEmpty
                ? _adminController.currentDriverName.value
                : data.name;
            displayEmail = _adminController.currentEmail.value.isNotEmpty
                ? _adminController.currentEmail.value
                : data.email;
            displayPost = '欢迎使用交通违法行为处理管理系统管理员端';
          }

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
            child: ListTile(
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
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: defaultTextColor,
                            letterSpacing: 0.5,
                            fontFamily: 'SimsunExtG',
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 60), // Increased spacing
                  Expanded(
                    child: Text(
                      displayPost,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: subtitleTextColor,
                            letterSpacing: 0.2,
                            fontFamily: 'SimsunExtG',
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                displayEmail,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      color: subtitleTextColor,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                      fontFamily: 'SimsunExtG',
                    ),
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
            ),
          );
        });
      },
    );
  }
}
