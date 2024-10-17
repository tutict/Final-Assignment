import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/components/user_header.dart';
import 'package:final_assignment_front/features/dashboard/views/components/user_sidebar.dart';
import 'package:final_assignment_front/shared_components/responsive_builder.dart';
import 'package:final_assignment_front/shared_components/user_screen_swiper.dart';
import 'package:final_assignment_front/shared_components/user_tools_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserDashboard extends GetView<UserDashboardController> {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: controller.scaffoldKey,
      drawer: _buildDrawer(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Flexible(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.lightBlueAccent,
                        Colors.white,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: _buildResponsiveLayout(context),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.lightBlueAccent,
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget? _buildDrawer(BuildContext context) {
    return ResponsiveBuilder.isDesktop(context)
        ? null
        : Drawer(
      child: Padding(
        padding: const EdgeInsets.only(top: kSpacing),
        child: UserSidebar(data: controller.getSelectedProject()),
      ),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context) {
    return ResponsiveBuilder(
      mobileBuilder: (context, constraints) => _buildLayout(context),
      tabletBuilder: (context, constraints) => _buildLayout(context),
      desktopBuilder: (context, constraints) =>
          _buildLayout(context, isDesktop: true),
    );
  }

  Widget _buildLayout(BuildContext context, {bool isDesktop = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: kSpacing * (kIsWeb || isDesktop ? 1 : 2)),
        _buildHeader(onPressedMenu: !isDesktop ? controller.openDrawer : null),
        const SizedBox(height: kSpacing / 2),
        const Divider(),
        _buildUserScreenSwiper(),
        _buildUserToolsCard(),
      ],
    );
  }

  Widget _buildUserScreenSwiper() {
    return SizedBox(
      height: 250,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kSpacing),
        child: UserScreenSwiper(onPressed: () {}),
      ),
    );
  }

  Widget _buildUserToolsCard() {
    return SizedBox(
      height: 150,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kSpacing),
        child: UserToolsCard(
          onPressed: () {},
          onPressedSecond: () {},
          onPressedThird: () {},
          onPressedFourth: () {},
          onPressedFifth: () {},
          onPressedSixth: () {},
        ),
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
                tooltip: "Menu",
              ),
            ),
          const Expanded(child: UserHeader()),
        ],
      ),
    );
  }
}
