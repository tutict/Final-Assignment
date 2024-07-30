import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/components/user_header.dart';
import 'package:final_assignment_front/shared_components/police_card.dart';
import 'package:final_assignment_front/shared_components/responsive_builder.dart';
import 'package:final_assignment_front/features/dashboard/views/components/user_sidebar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';



class UserDashboardScreen extends GetView<UserDashboardController> {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: controller.scaffoldKey,
      drawer: (ResponsiveBuilder.isDesktop(context))
          ? null
          : Drawer(
        child: Padding(
          padding: const EdgeInsets.only(top: kSpacing),
          child: UserSidebar(data: controller.getSelectedProject()),
        ),
      ),
      body: SingleChildScrollView(
          child: ResponsiveBuilder(
            mobileBuilder: (context, constraints) {
              return Column(children: [
                const SizedBox(height: kSpacing * (kIsWeb ? 1 : 2)),
                _buildHeader(onPressedMenu: () => controller.openDrawer()),
                const SizedBox(height: kSpacing / 2),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kSpacing),
                  child: GetPremiumCard(onPressed: () {}),
                ),
              ]);
            },
            tabletBuilder: (context, constraints) {
              return Column(
                children: [
                  const SizedBox(height: kSpacing * (kIsWeb ? 1 : 2)),
                  _buildHeader(onPressedMenu: () => controller.openDrawer()),
                  const SizedBox(height: kSpacing / 2),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kSpacing),
                    child: GetPremiumCard(onPressed: () {}),
                  ),
                ],
              );
            },
            desktopBuilder: (context, constraints) {
              return Column(
                children: [
                  const SizedBox(height: kSpacing),
                  _buildHeader(),
                  const SizedBox(height: kSpacing / 2),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kSpacing),
                    child: GetPremiumCard(onPressed: () {}),
                  ),
                ],
              );
            },
          )),
    );
  }

  Widget _buildHeader({Function()? onPressedMenu}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: Row(
        children: [
          if (onPressedMenu != null)
            Padding(
              padding: const EdgeInsets.only(right: kSpacing),
              child: IconButton(
                onPressed: onPressedMenu,
                icon: const Icon(EvaIcons.menu),
                tooltip: "menu",
              ),
            ),
          const Expanded(child: UserHeader()),
        ],
      ),
    );
  }
}
