import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/dashboard/models/profile.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/ai_chat.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/notification_bar.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/profile_tile.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_chrome.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_top_bar_actions.dart';
import 'package:final_assignment_front/shared_components/floating_window.dart';
import 'package:final_assignment_front/shared_components/post_card.dart';
import 'package:final_assignment_front/shared_components/responsive_builder.dart';
import 'package:final_assignment_front/shared_components/selection_button.dart';
import 'package:final_assignment_front/shared_components/user_screen_swiper.dart';
import 'package:final_assignment_front/shared_components/user_news_card.dart';
import 'package:final_assignment_front/utils/navigation/page_resolver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;
import 'dart:math' as math;

part 'components/user_header.dart';

part 'components/user_sidebar.dart';

class UserDashboard extends GetView<UserDashboardController> with FloatingBase {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    controller.pageResolver ??= resolveDashboardPage;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double expandedSidebarWidth =
        (screenWidth * 0.2).clamp(260.0, 320.0).toDouble();
    const double kHeaderTotalHeight = 112;

    return Obx(() {
      final themeData = controller.currentBodyTheme.value;

      return Theme(
        data: themeData,
        child: Scaffold(
          backgroundColor: themeData.scaffoldBackgroundColor,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kHeaderTotalHeight),
            child: Builder(
              builder: (context) => _buildHeaderSection(context, screenWidth),
            ),
          ),
          body: Builder(
            builder: (context) => Material(
              color: themeData.scaffoldBackgroundColor,
              child: DashboardBackdrop(
                child: ResponsiveBuilder(
                  mobileBuilder: (context, constraints) {
                    return Stack(
                      children: [
                        SingleChildScrollView(
                          child: _buildLayout(context),
                        ),
                        Obx(() => _buildSidebar(context)),
                        _buildResponsiveChatDrawer(context, screenWidth),
                      ],
                    );
                  },
                  tabletBuilder: (context, constraints) {
                    final theme = Theme.of(context);
                    return Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(
                              () => AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                width: controller.isSidebarCollapsed.value
                                    ? 76.0
                                    : screenWidth * 0.3,
                                height: screenHeight,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface
                                      .withValues(alpha: 0.96),
                                  border: Border(
                                    right: BorderSide(
                                      color: theme.colorScheme.outlineVariant
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ),
                                child: const UserSidebar(),
                              ),
                            ),
                            SizedBox(
                              width: screenWidth * 0.7,
                              child: SingleChildScrollView(
                                child: _buildLayout(context),
                              ),
                            ),
                          ],
                        ),
                        _buildResponsiveChatDrawer(context, screenWidth),
                      ],
                    );
                  },
                  desktopBuilder: (context, constraints) {
                    final theme = Theme.of(context);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(
                          () => AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            width: controller.isSidebarCollapsed.value
                                ? 76.0
                                : expandedSidebarWidth,
                            height: screenHeight,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface
                                  .withValues(alpha: 0.96),
                              border: Border(
                                right: BorderSide(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                            child: const UserSidebar(),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildLayout(context, isDesktop: true),
                          ),
                        ),
                        Obx(
                          () => AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            width: controller.isChatExpanded.value
                                ? (screenWidth * 0.3 > 150
                                    ? screenWidth * 0.3
                                    : 150)
                                : 0,
                            height: screenHeight,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface
                                  .withValues(alpha: 0.96),
                              border: Border(
                                left: BorderSide(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                            child: controller.isChatExpanded.value
                                ? _buildSideContent(context)
                                : null,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSideContent(BuildContext context) {
    return const AiChat();
  }

  Widget _buildResponsiveChatDrawer(BuildContext context, double screenWidth) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final availableWidth = math.max(260.0, screenWidth - 24);
    final targetWidth =
        screenWidth < 700 ? screenWidth * 0.92 : screenWidth * 0.46;
    final drawerWidth = math.min(targetWidth, math.min(420.0, availableWidth));

    return Obx(() {
      final expanded = controller.isChatExpanded.value;

      return IgnorePointer(
        ignoring: !expanded,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          opacity: expanded ? 1 : 0,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: controller.toggleChat,
                  child: Container(
                    color: Colors.black.withValues(alpha: dark ? 0.34 : 0.18),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                top: 12,
                right: expanded ? 12 : -drawerWidth - 12,
                bottom: 12,
                width: drawerWidth,
                child: Material(
                  color: Colors.transparent,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          scheme.surface.withValues(alpha: dark ? 0.98 : 0.99),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(
                          alpha: dark ? 0.42 : 0.58,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: dark ? 0.36 : 0.18),
                          blurRadius: 30,
                          offset: const Offset(-10, 18),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: scheme.primary.withValues(
                                      alpha: dark ? 0.22 : 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: scheme.primary,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'AI 助手',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: scheme.onSurface,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: controller.toggleChat,
                                  icon: Icon(
                                    Icons.close,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  tooltip: '关闭 AI 助手',
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: scheme.outlineVariant.withValues(
                              alpha: dark ? 0.36 : 0.55,
                            ),
                          ),
                          const Expanded(child: AiChat()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLayout(BuildContext context, {bool isDesktop = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacing,
        vertical: kSpacing / 4,
      ),
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
          Obx(() {
            final pageContent = controller.selectedPage.value;
            if (pageContent != null) {
              return DashboardPanel(
                padding: EdgeInsets.zero,
                height: MediaQuery.of(context).size.height * 0.82,
                child: _buildUserScreenSidebarTools(context),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserOverview(context),
                const SizedBox(height: kSpacing),
                _buildProfileSection(context),
                _buildUserScreenSwiper(context),
                const SizedBox(height: kSpacing),
                _buildUserToolsCard(context),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUserOverview(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: kSpacing),
      child: DashboardSectionHeader(
        title: '个人工作台',
        subtitle: '查看违法通知、办事进度和常用办理入口。',
      ),
    );
  }

  Widget _buildUserScreenSwiper(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: UserScreenSwiper(onPressed: () {}),
    );
  }

  Widget _buildUserScreenSidebarTools(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Obx(
        () =>
            controller.selectedPage.value ??
            const Center(child: Text('请选择一个页面')),
      ),
    );
  }

  Widget _buildUserToolsCard(BuildContext context) {
    final height = (MediaQuery.of(context).size.height * 0.58)
        .clamp(470.0, 560.0)
        .toDouble();

    return DashboardPanel(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.zero,
      child: UserNewsCard(
        onPressed: () {
          controller.navigateToPage(Routes.latestOffenseNewsPage);
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
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final bool isDesktop = ResponsiveBuilder.isDesktop(context);
    final bool showSidebar = isDesktop || controller.isSidebarOpen.value;
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: showSidebar ? 300 : 0,
      height: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.98),
        border: Border(
          right: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      child: showSidebar
          ? const Padding(
              padding: EdgeInsets.fromLTRB(16.0, kSpacing * 2, 16.0, kSpacing),
              child: UserSidebar(),
            )
          : null,
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: Obx(() {
        final Profile profile = controller.currentProfile;
        return ProfilTile(
          data: profile,
          onPressedNotification: () => developer.log("Notification clicked"),
          controller: controller,
        );
      }),
    );
  }

  Widget _buildHeaderSection(BuildContext context, double screenWidth) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.95 : 0.98),
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),
          _buildHeader(
            context: context,
            onPressedMenu: () => controller.openDrawer(),
            screenWidth: screenWidth,
          ),
          const SizedBox(height: 15),
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    Function()? onPressedMenu,
    required double screenWidth,
  }) {
    final scheme = Theme.of(context).colorScheme;
    const double horizontalPadding = kSpacing / 2;
    final double availableWidth = screenWidth - 2 * horizontalPadding;
    const double mobileBreakpoint = 600.0;
    final double menuIconWidth = onPressedMenu != null ? 48.0 : 0.0;
    final double headerContentAvailableWidth = math.max(
      0,
      availableWidth - menuIconWidth - DashboardTopBarActions.totalWidth,
    );

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
                icon: Icon(Icons.menu, color: scheme.onSurfaceVariant),
                tooltip: "菜单",
              ),
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: headerContentAvailableWidth),
              child: const UserHeader(),
            ),
            Obx(
              () => DashboardTopBarActions(
                chatActive: controller.isChatExpanded.value,
                onChatPressed: controller.toggleChat,
                onThemePressed: controller.toggleBodyTheme,
              ),
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
