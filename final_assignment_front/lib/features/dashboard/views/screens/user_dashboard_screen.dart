import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/components/user_header.dart';
import 'package:final_assignment_front/features/dashboard/views/components/user_sidebar.dart';
import 'package:final_assignment_front/shared_components/responsive_builder.dart';
import 'package:final_assignment_front/shared_components/user_screen_swiper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class UserDashboardScreen extends GetView<UserDashboardController> {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: controller.scaffoldKey,
      drawer: ResponsiveBuilder.isDesktop(context)
          ? null
          : Drawer(
        child: Padding(
          padding: const EdgeInsets.only(top: kSpacing),
          child: UserSidebar(data: controller.getSelectedProject()),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue,            // Start with a darker blue
                    Colors.lightBlueAccent, // End with a lighter blue
                  ],
                  begin: Alignment.topCenter,   // Start the gradient from the top
                  end: Alignment.topLeft,  // End the gradient at the bottom
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  maxHeight: 80,
                ),
                child: ResponsiveBuilder(
                  mobileBuilder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: kSpacing * (kIsWeb ? 1 : 2)),
                        _buildHeader(onPressedMenu: () => controller.openDrawer()),
                        const SizedBox(height: kSpacing / 2),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: kSpacing),
                          child: UserScreenSwiper(onPressed: () {}),
                        ),
                      ],
                    );
                  },
                  tabletBuilder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: kSpacing * (kIsWeb ? 1 : 2)),
                        _buildHeader(onPressedMenu: () => controller.openDrawer()),
                        const SizedBox(height: kSpacing / 2),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: kSpacing),
                          child: UserScreenSwiper(onPressed: () {}),
                        ),
                      ],
                    );
                  },
                  desktopBuilder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: kSpacing),
                        _buildHeader(),
                        const SizedBox(height: kSpacing / 2),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: kSpacing),
                          child: UserScreenSwiper(onPressed: () {}),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action for the floating action button
        },
        child: const Icon(Icons.chat),
      ),
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
              tooltip: "¹¦ÄÜ²Ëµ¥",
            ),
          ),
        const Expanded(child: UserHeader()),
      ],
    ),
        );
  }
}
