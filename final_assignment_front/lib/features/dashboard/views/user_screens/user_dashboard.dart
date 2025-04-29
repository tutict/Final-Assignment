library user_dashboard;

import 'dart:developer';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/config/themes/app_theme.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/dashboard/models/profile.dart';
import 'package:final_assignment_front/features/dashboard/views/components/ai_chat.dart';
import 'package:final_assignment_front/features/dashboard/views/components/profile_tile.dart';
import 'package:final_assignment_front/shared_components/case_card.dart';
import 'package:final_assignment_front/shared_components/floating_window.dart';
import 'package:final_assignment_front/shared_components/post_card.dart';
import 'package:final_assignment_front/shared_components/project_card.dart';
import 'package:final_assignment_front/shared_components/responsive_builder.dart';
import 'package:final_assignment_front/shared_components/selection_button.dart';
import 'package:final_assignment_front/shared_components/today_text.dart';
import 'package:final_assignment_front/shared_components/user_screen_swiper.dart';
import 'package:final_assignment_front/shared_components/user_news_card.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';
import 'package:final_assignment_front/utils/mixins/app_mixins.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/notification_bar.dart';

part '../../bindings/user_dashboard_binding.dart';

part '../../controllers/user_dashboard_screen_controller.dart';

part '../components/user_header.dart';

part '../components/user_sidebar.dart';

class UserDashboard extends GetView<UserDashboardController>
    with FloatingBase, NavigationMixin {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    const double kHeaderTotalHeight = 32 + 50 + 15 + 1;

    return Scaffold(
      key: controller.scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kHeaderTotalHeight),
        child: _buildHeaderSection(context, screenWidth),
      ),
      body: Obx(
        () => Theme(
          data: controller.currentBodyTheme.value,
          child: Material(
            child: ResponsiveBuilder(
              mobileBuilder: (context, constraints) {
                return Stack(
                  children: [
                    SingleChildScrollView(
                      child: _buildLayout(context),
                    ),
                    Obx(() => _buildSidebar(context)),
                  ],
                );
              },
              tabletBuilder: (context, constraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: screenWidth * 0.3,
                      child: UserSidebar(data: controller.getSelectedProject()),
                    ),
                    SizedBox(
                      width: screenWidth * 0.7,
                      child: SingleChildScrollView(
                        child: _buildLayout(context),
                      ),
                    ),
                  ],
                );
              },
              desktopBuilder: (context, constraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: screenWidth * 0.2,
                      height: screenHeight,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border: Border(
                            right: BorderSide(color: Colors.grey.shade300)),
                        boxShadow: kBoxShadows,
                      ),
                      child: UserSidebar(data: controller.getSelectedProject()),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          border: Border(
                              right: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: SingleChildScrollView(
                          child: _buildLayout(context),
                        ),
                      ),
                    ),
                    Obx(
                      () => TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: controller.isChatExpanded.value ? 0 : 150,
                          end: controller.isChatExpanded.value
                              ? (screenWidth * 0.3 > 150
                                  ? screenWidth * 0.3
                                  : 150)
                              : 0,
                        ),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        builder: (context, width, child) {
                          return Container(
                            width: width,
                            height: screenHeight,
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).cardColor.withOpacity(0.9),
                            ),
                            child: width >= 150
                                ? _buildSideContent(context)
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideContent(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: const AiChat(),
    );
  }

  Widget _buildLayout(BuildContext context, {bool isDesktop = false}) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: kSpacing, vertical: kSpacing / 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: kSpacing * (kIsWeb || isDesktop ? 0.5 : 0.75)),
            Obx(() {
              if (controller.driverLicenseNumber.value.isEmpty ||
                  controller.idCardNumber.value.isEmpty) {
                return NotificationBar(
                  data: const NotificationBarData(
                    message: "请及时完善身份证号和驾驶证号",
                    icon: EvaIcons.alertCircleOutline,
                    actionText: "去输入",
                    routeName: '/personalInfo',
                  ),
                  onPressedAction: navigateToPersonalInfo,
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: kSpacing),
            const Divider(),
            Obx(() {
              final pageContent = controller.selectedPage.value;
              if (pageContent != null) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kBorderRadius),
                    boxShadow: kBoxShadows,
                  ),
                  child: _buildUserScreenSidebarTools(context),
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSection(context),
                    _buildUserScreenSwiper(context),
                    const SizedBox(height: kSpacing),
                    _buildUserToolsCard(context),
                  ],
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildUserScreenSwiper(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.55,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kSpacing),
        child: UserScreenSwiper(onPressed: () {}),
      ),
    );
  }

  Widget _buildUserScreenSidebarTools(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Obx(() {
            final pageContent = controller.selectedPage.value;
            return pageContent ?? const Center(child: Text('请选择一个页面'));
          }),
        ),
      ),
    );
  }

  Widget _buildUserToolsCard(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.surface.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, opacity, child) {
              return Opacity(
                opacity: opacity,
                child: child,
              );
            },
            child: UserNewsCard(
              onPressed: () {
                controller
                    .navigateToPage(Routes.latestTrafficViolationNewsPage);
              },
              onPressedSecond: () {
                controller.navigateToPage(Routes.finePaymentNoticePage);
              },
              onPressedThird: () {
                controller.navigateToPage(Routes.accidentQuickGuidePage);
              },
              onPressedFourth: () {
                controller.navigateToPage(Routes.accidentProgressPage);
              },
              onPressedFifth: () {
                controller.navigateToPage(Routes.accidentEvidencePage);
              },
              onPressedSixth: () {
                controller.navigateToPage(Routes.accidentVideoQuickPage);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final bool isDesktop = ResponsiveBuilder.isDesktop(context);
    final bool showSidebar = isDesktop || controller.isSidebarOpen.value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: showSidebar ? 300 : 0,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: kBoxShadows,
      ),
      child: showSidebar
          ? Padding(
              padding:
                  const EdgeInsets.fromLTRB(16.0, kSpacing * 2, 16.0, kSpacing),
              child: UserSidebar(data: controller.getSelectedProject()),
            )
          : null,
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: Obx(() {
        final Profile profile = controller.currentProfile; // 使用 Profile 类型
        return ProfilTile(
          data: profile,
          onPressedNotification: () => log("Notification clicked"),
        );
      }),
    );
  }

  Widget _buildHeaderSection(BuildContext context, double screenWidth) {
    return Container(
      color: Colors.blueAccent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),
          _buildHeader(
            onPressedMenu: () => controller.openDrawer(),
            screenWidth: screenWidth,
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, thickness: 1),
        ],
      ),
    );
  }

  Widget _buildHeader({
    Function()? onPressedMenu,
    required double screenWidth,
  }) {
    const double horizontalPadding = kSpacing / 2;
    final double availableWidth = screenWidth - 2 * horizontalPadding;
    const double mobileBreakpoint = 600.0;
    final double menuIconWidth = onPressedMenu != null ? 48.0 : 0.0;
    const double iconWidth = 48.0;
    const double iconSpacing = 4.0;
    const double iconsTotalWidth = iconWidth * 2 + iconSpacing;
    final double headerContentAvailableWidth =
        availableWidth - menuIconWidth - iconsTotalWidth;

    return SizedBox(
      height: 50,
      child: Container(
        width: availableWidth,
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Row(
          children: [
            if (screenWidth < mobileBreakpoint && onPressedMenu != null)
              IconButton(
                onPressed: () => controller.toggleSidebar(),
                icon: const Icon(Icons.menu),
                tooltip: "菜单",
              ),
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: headerContentAvailableWidth),
              child: const UserHeader(),
            ),
            IconButton(
              onPressed: () => controller.toggleChat(),
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: "AIChat",
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => controller.toggleBodyTheme(),
              icon: const Icon(Icons.brightness_6),
              tooltip: "切换明暗主题",
            ),
          ],
        ),
      ),
    );
  }

  void navigateToPersonalInfo() {
    developer.log('NotificationBar tapped, navigating to /personalInfo');
    controller.navigateToPage(Routes.personalMain);
  }
}
