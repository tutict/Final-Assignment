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
                  child: ResponsiveBuilder(
                    mobileBuilder: (context, constraints) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: kSpacing * (kIsWeb ? 1 : 2)),
                          _buildHeader(
                              onPressedMenu: () => controller.openDrawer()),
                          const SizedBox(height: kSpacing / 2),
                          const Divider(),
                          SizedBox(
                            height: 250,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: kSpacing),
                              child: UserScreenSwiper(onPressed: () {}),
                            ),
                          ),
                          SizedBox(
                            height: 150,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: kSpacing),
                              child: UserToolsCard(
                                title: 'User Tools',
                                icon: EvaIcons.person,
                                onPressed: () {},
                                onPressedSecond: () {},
                                onPressedThird: () {},
                                onPressedFourth: () {},
                                onPressedFifth: () {},
                                onPressedSixth: () {},
                                onPressedSeventh: () {},
                                onPressedEighth: () {},
                                onPressedNinth: () {},
                                onPressedTenth: () {},
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    tabletBuilder: (context, constraints) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: kSpacing * (kIsWeb ? 1 : 2)),
                          _buildHeader(
                              onPressedMenu: () => controller.openDrawer()),
                          const SizedBox(height: kSpacing / 2),
                          const Divider(),
                          SizedBox(
                            height: 250,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: kSpacing),
                              child: UserScreenSwiper(onPressed: () {}),
                            ),
                          ),
                          SizedBox(
                            height: 150,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: kSpacing),
                              child: UserToolsCard(
                                title: 'User Tools',
                                icon: EvaIcons.person,
                                onPressed: () {},
                                onPressedSecond: () {},
                                onPressedThird: () {},
                                onPressedFourth: () {},
                                onPressedFifth: () {},
                                onPressedSixth: () {},
                                onPressedSeventh: () {},
                                onPressedEighth: () {},
                                onPressedNinth: () {},
                                onPressedTenth: () {},
                              ),
                            ),
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
                          SizedBox(
                            height: 250,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: kSpacing),
                              child: UserScreenSwiper(onPressed: () {}),
                            ),
                          ),
                          SizedBox(
                            height: 150,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: kSpacing),
                              child: UserToolsCard(
                                title: 'User Tools',
                                icon: EvaIcons.person,
                                onPressed: () {},
                                onPressedSecond: () {},
                                onPressedThird: () {},
                                onPressedFourth: () {},
                                onPressedFifth: () {},
                                onPressedSixth: () {},
                                onPressedSeventh: () {},
                                onPressedEighth: () {},
                                onPressedNinth: () {},
                                onPressedTenth: () {},
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
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
