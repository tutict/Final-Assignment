import 'package:final_assignment_front/config/navigation/shell_navigation.dart';
import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/core/auth/role_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShellRedirect extends StatefulWidget {
  const ShellRedirect({
    super.key,
    this.page,
    this.guide,
    this.home = false,
    this.openChat = false,
    this.forceUser = false,
    this.forceManager = false,
    this.section,
  });

  final String? page;
  final String? guide;
  final bool home;
  final bool openChat;
  final bool forceUser;
  final bool forceManager;
  final String? section;

  @override
  State<ShellRedirect> createState() => _ShellRedirectState();
}

class _ShellRedirectState extends State<ShellRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _go());
  }

  Future<void> _go() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('roles') ?? prefs.getString('userRole');
    final staff = RoleUtils.canAccessStaffDashboard(role);
    final target = widget.forceManager
        ? RoutePaths.dashboard
        : widget.forceUser
            ? RoutePaths.userDashboard
            : (staff ? RoutePaths.dashboard : RoutePaths.userDashboard);
    var page = widget.home ? 'homePage' : widget.page;
    if (widget.openChat) {
      final saved = staff ? ShellSession.managerPage : ShellSession.userPage;
      if (saved != null && saved.isNotEmpty && saved != RoutePaths.aiChat) {
        page = saved == 'homePage' ? null : saved;
      }
    }
    Get.offNamed(target, arguments: {
      'page': page,
      'guide': widget.guide,
      'openChat': widget.openChat,
      'section': widget.section,
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
