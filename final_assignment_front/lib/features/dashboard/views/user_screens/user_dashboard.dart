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
/// 本页面采用响应式布局，根据设备尺寸构建不同布局：
/// - 移动端：采用 Drawer 和 Stack 叠加侧边栏与主体内容，并使用独立的主题（通过 controller.currentBodyTheme）。
/// - 平板端：固定侧边栏和主体内容分栏显示。
/// - 桌面端：左侧固定侧边栏，中间滚动主体、右侧固定工具或聊天区域。
class UserDashboard extends GetView<UserDashboardController>
    with FloatingBase, NavigationMixin {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: controller.scaffoldKey,
      // 移动端使用 Drawer 显示侧边栏，桌面端侧边栏直接显示在页面中
      drawer:
          ResponsiveBuilder.isDesktop(context) ? null : _buildDrawer(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (ResponsiveBuilder.isDesktop(context)) {
            // 桌面端布局：左侧固定侧边栏，中间滚动内容，右侧固定工具区域
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: constraints.maxWidth * 0.2,
                  height: constraints.maxHeight,
                  child: _buildSidebar(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [_buildLayout(context)],
                    ),
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth * 0.3,
                  height: constraints.maxHeight,
                  child: _buildSideContent(context),
                ),
              ],
            );
          } else if (ResponsiveBuilder.isTablet(context)) {
            // 平板端布局：左侧固定侧边栏，右侧滚动主要内容
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: constraints.maxWidth * 0.3,
                  child: _buildSidebar(context),
                ),
                SizedBox(
                  width: constraints.maxWidth * 0.7,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildLayout(context),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            // 移动端布局：使用 Stack 叠加主体内容和侧边栏，通过 controller 控制侧边栏显示（侧边栏从 AnimatedContainer 动画显示）
            return Obx(
              () => Theme(
                data: controller.currentBodyTheme.value,
                child: Stack(
                  children: [
                    // 主体内容：滚动显示各模块
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildLayout(context),
                        ],
                      ),
                    ),
                    // 侧边栏：根据 controller.isSidebarOpen 动画显示
                    Obx(() => _buildSidebar(context)),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  /// 移动端 Drawer 构建
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: UserSidebar(
        data: controller.getSelectedProject(),
      ),
    );
  }

  Widget _buildSideContent(BuildContext context) {
    return Container(
      // 根据需要设置背景色等
      color: Theme.of(context).scaffoldBackgroundColor,
      child: const ChatConversationWidget(),
    );
  }

  /// 构建桌面/平板端侧边栏
  Widget _buildSidebar(BuildContext context) {
    // 桌面端侧边栏始终显示；移动端根据 controller.isSidebarOpen 状态显示（宽度动画过渡）
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
              child: UserSidebar(
                data: controller.getSelectedProject(),
              ),
            )
          : null,
    );
  }

  /// 构建整体布局区域
  ///
  /// 此区域包括头部、页面主体（根据 controller.selectedPage 显示不同内容）或用户屏幕轮播、工具卡片
  Widget _buildLayout(BuildContext context, {bool isDesktop = false}) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: kSpacing, vertical: kSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: kSpacing * (kIsWeb || isDesktop ? 2.5 : 3.5)),
          _buildHeader(
              onPressedMenu: !isDesktop ? controller.openDrawer : null),
          const SizedBox(height: kSpacing / 2),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Obx(() {
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
            ),
          ),
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

  /// 构建头部区域
  ///
  /// 包含菜单按钮、用户头像和主题切换按钮
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
                icon: const Icon(Icons.menu),
                tooltip: "菜单",
              ),
            ),
          const Expanded(child: UserHeader()),
          IconButton(
            onPressed: () {
              controller.navigateToPage(AppPages.aiChat);
            },
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            tooltip: "Chat",
          ),
          IconButton(
            onPressed: () {
              // 这里调用主题切换方法
              controller.toggleBodyTheme();
            },
            icon: const Icon(Icons.brightness_6, color: Colors.white),
            tooltip: "切换主题",
          ),
        ],
      ),
    );
  }
}
