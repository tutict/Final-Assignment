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

/// 用户仪表板页面
///
/// UserDashboard 类继承自GetView，用于构建用户仪表板页面。
/// 它包含了一个 Scaffold，提供了一个可选的侧边栏、头部、身体内容，
/// 以及一个浮动操作按钮。
class UserDashboard extends GetView<UserDashboardController> {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: controller.scaffoldKey,
      drawer: _buildDrawer(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              if (ResponsiveBuilder.isDesktop(context)) _buildSidebar(context),
              Expanded(
                child: Column(
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
                ),
              ),
            ],
          );
        },
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

  Widget _buildSidebar(BuildContext context) {
    return SizedBox(
      width: 250,
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
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: kSpacing, vertical: kSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: kSpacing * (kIsWeb || isDesktop ? 1 : 2)),
          _buildHeader(
              onPressedMenu: !isDesktop ? controller.openDrawer : null),
          const SizedBox(height: kSpacing / 2),
          const Divider(),
          _buildUserScreenSwiper(),
          const SizedBox(height: kSpacing),
          _buildUserToolsCard(),
        ],
      ),
    );
  }

  Widget _buildUserScreenSwiper() {
    return SizedBox(
      height: 300,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kSpacing),
        child: UserScreenSwiper(onPressed: () {}),
      ),
    );
  }

  Widget _buildUserToolsCard() {
    return SizedBox(
      height: 200,
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
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline,
                color: Colors.white),
            tooltip: "Chat",
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.brightness_6, color: Colors.white),
            tooltip: "Toggle Theme",
          ),
        ],
      ),
    );
  }
}
