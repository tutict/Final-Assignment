library user_dashboard;

import 'dart:developer';
import 'dart:ui';

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/config/themes/app_theme.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/dashboard/views/components/ai_chat.dart';
import 'package:final_assignment_front/shared_components/case_card.dart';
import 'package:final_assignment_front/shared_components/chatting_card.dart';
import 'package:final_assignment_front/shared_components/floating_window.dart';
import 'package:final_assignment_front/shared_components/post_card.dart';
import 'package:final_assignment_front/shared_components/project_card.dart';
import 'package:final_assignment_front/shared_components/responsive_builder.dart';
import 'package:final_assignment_front/shared_components/search_field.dart';
import 'package:final_assignment_front/shared_components/selection_button.dart';
import 'package:final_assignment_front/shared_components/today_text.dart';
import 'package:final_assignment_front/shared_components/user_screen_swiper.dart';
import 'package:final_assignment_front/shared_components/user_tools_card.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';
import 'package:final_assignment_front/utils/mixins/app_mixins.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

part '../../bindings/user_dashboard_binding.dart';

part '../../controllers/user_dashboard_screen_controller.dart';

part '../components/user_header.dart';

part '../components/user_sidebar.dart';

part '../../models/user_profile.dart';

/// 用户仪表板页面
///
/// 此页面在 appBar 中固定显示 Header 区域，主体内容根据设备类型构建响应式布局，
/// 所有平台均使用 AnimatedContainer 显示侧边栏（与 manager_dashboard 保持一致）。
class UserDashboard extends GetView<UserDashboardController>
    with FloatingBase, NavigationMixin {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取屏幕尺寸
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    // 计算顶部 Header 总高度：上边距 32 + header 行 50 + 下边距 15 + Divider 高度 1
    const double kHeaderTotalHeight = 32 + 50 + 15 + 1;

    return Scaffold(
      key: controller.scaffoldKey,
      // 固定在 appBar 中显示 Header
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kHeaderTotalHeight),
        child: _buildHeaderSection(context, screenWidth),
      ),
      // 移除 Drawer，侧边栏统一采用 AnimatedContainer 显示
      body: Obx(
        () => Theme(
          data: controller.currentBodyTheme.value,
          child: Material(
            child: ResponsiveBuilder(
              mobileBuilder: (context, constraints) {
                // 移动端布局：Stack 叠加主体内容与侧边栏
                return Stack(
                  children: [
                    // 主体内容（滚动区域）
                    SingleChildScrollView(
                      child: _buildLayout(context),
                    ),
                    // 侧边栏：使用 AnimatedContainer 根据 controller.isSidebarOpen 显示
                    Obx(() => _buildSidebar(context)),
                  ],
                );
              },
              tabletBuilder: (context, constraints) {
                // 平板端布局：左侧侧边栏、右侧主体内容分栏显示
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
                // 桌面端布局：左侧侧边栏、中间滚动主体、右侧固定工具/聊天区域
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: screenWidth * 0.2,
                      height: screenHeight,
                      child: UserSidebar(data: controller.getSelectedProject()),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildLayout(context),
                      ),
                    ),
                    SizedBox(
                      width: screenWidth * 0.3,
                      height: screenHeight,
                      child: _buildSideContent(context),
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

  /// 构建右侧工具/聊天区域
  ///
  /// 此处嵌入 AI 聊天对话组件，与 manager_dashboard 保持一致。
  Widget _buildSideContent(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: const AiChat(),
    );
  }

  /// 构建整体布局区域
  ///
  /// 包含用户信息、页面主体（或用户屏幕轮播和工具卡片）。
  Widget _buildLayout(BuildContext context, {bool isDesktop = false}) {
    // 计算屏幕宽度
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: kSpacing, vertical: kSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 保留一定的上间距
          SizedBox(height: kSpacing * (kIsWeb || isDesktop ? 2.5 : 3.5)),
          // 这里不再重复显示 Header，因为 Header 已在 appBar 中固定显示
          const Divider(),
          // 主体内容区域
          Obx(() {
            final pageContent = controller.selectedPage.value;
            if (pageContent != null) {
              return Padding(
                padding: const EdgeInsets.all(kSpacing),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kBorderRadius),
                    boxShadow: kBoxShadows,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildUserScreenSidebarTools(context),
                  ),
                ),
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserScreenSwiper(context),
                  const SizedBox(height: kSpacing),
                  _buildUserToolsCard(context),
                ],
              );
            }
          }),
        ],
      ),
    );
  }

  /// 构建用户屏幕轮播
  Widget _buildUserScreenSwiper(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.55,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kSpacing),
        child: UserScreenSwiper(onPressed: () {}),
      ),
    );
  }

  /// 构建用户屏幕侧边工具区域
  Widget _buildUserScreenSidebarTools(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Expanded(
                child: Obx(() {
                  final pageContent = controller.selectedPage.value;
                  return pageContent != null
                      ? Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: pageContent,
                        )
                      : const SizedBox(width: 100, height: 100);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建用户工具卡片
  Widget _buildUserToolsCard(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kSpacing),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 500),
              child: UserToolsCard(
                onPressed: () {
                  initializeFloating(
                      context, getPageForRoute('fineInformation')!);
                },
                onPressedSecond: () {
                  initializeFloating(
                      context, getPageForRoute('onlineProcessingProgress')!);
                },
                onPressedThird: () {
                  initializeFloating(context, getPageForRoute('userAppeal')!);
                },
                onPressedFourth: () {
                  initializeFloating(
                      context, getPageForRoute('vehicleManagement')!);
                },
                onPressedFifth: () {
                  initializeFloating(
                      context, getPageForRoute('managerPersonalPage')!);
                },
                onPressedSixth: () {
                  initializeFloating(
                      context, getPageForRoute('managerSetting')!);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建侧边栏，使用 AnimatedContainer 实现平滑过渡
  Widget _buildSidebar(BuildContext context) {
    final bool isDesktop = ResponsiveBuilder.isDesktop(context);
    // 对于桌面端侧边栏一直显示；对于手机端，根据控制器状态决定是否显示
    final bool showSidebar = isDesktop || controller.isSidebarOpen.value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: showSidebar ? 300 : 0,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: kBoxShadows, // 使用全局阴影效果
      ),
      child: showSidebar
          ? Padding(
              padding:
                  const EdgeInsets.fromLTRB(16.0, kSpacing * 2, 16.0, kSpacing),
              child: UserSidebar(
                data: controller.getSelectedProject(),
              ),
            )
          : null,
    );
  }

  /// 构建顶部 Header 区域（包含上下间距和分割线）
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
          const Divider(
            height: 1,
            thickness: 1,
          ),
        ],
      ),
    );
  }

  /// 构建顶部 Header 区域
  ///
  /// 包含菜单按钮、用户头像和主题切换按钮。
  Widget _buildHeader({
    Function()? onPressedMenu,
    required double screenWidth,
  }) {
    const double horizontalPadding = kSpacing / 2; // 使用较小的内边距
    final double availableWidth = screenWidth - 2 * horizontalPadding;
    const double mobileBreakpoint = 600.0;

    // 菜单图标和右侧图标的固定宽度（可根据实际情况调整）
    final double menuIconWidth = onPressedMenu != null ? 48.0 : 0.0;
    const double iconWidth = 48.0; // 右侧每个图标宽度预估值
    const double iconSpacing = 4.0; // 两个图标之间的间隔
    const double iconsTotalWidth = iconWidth * 2 + iconSpacing;

    // 剩余给中间部分的宽度
    final double headerContentAvailableWidth =
        availableWidth - menuIconWidth - iconsTotalWidth;

    return SizedBox(
      height: 50, // 固定高度 50 像素
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
            // 中间区域使用 ConstrainedBox 限制最大宽度
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: headerContentAvailableWidth,
              ),
              child:
                  const UserHeader(), // 该组件定义在 part '../components/header.dart'
            ),
            // 右侧固定的图标区域
            IconButton(
              onPressed: () => log("Chat icon pressed"),
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: "Chat",
            ),
            const SizedBox(width: 4), // 图标之间的小间隔
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
}
