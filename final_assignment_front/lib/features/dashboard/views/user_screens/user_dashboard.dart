library user_dashboard;

import 'dart:developer';
import 'dart:ui';

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
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
/// UserDashboard 类继承自GetView，用于构建用户仪表板页面。
/// 它包含了一个 Scaffold，提供了一个可选的侧边栏、头部、身体内容，
/// 以及一个浮动操作按钮，并添加了动画效果。
class UserDashboard extends GetView<UserDashboardController> with FloatingBase, NavigationMixin {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // 构建用户仪表板页面的主要布局
    return Scaffold(
      key: controller.scaffoldKey,
      drawer: _buildDrawer(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 根据屏幕大小构建不同的布局
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
                        child: _buildLayout(context,
                            isDesktop: ResponsiveBuilder.isDesktop(context)),
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

  /// 构建侧边栏
  ///
  /// 如果是桌面端，返回null，否则返回一个Drawer。
  Widget? _buildDrawer(BuildContext context) {
    return ResponsiveBuilder.isDesktop(context)
        ? null
        : Drawer(
            child: UserSidebar(
              data: controller.getSelectedProject(),
            ),
          );
  }

  /// 构建侧边栏
  ///
  /// 返回一个包含用户侧边栏的AnimatedContainer。
  Widget _buildSidebar(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: ResponsiveBuilder.isDesktop(context) ? 300 : 0,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: kBoxShadows, // 使用全局阴影效果
      ),
      child: ResponsiveBuilder.isDesktop(context)
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

  /// 构建页面布局
  ///
  /// 根据是否是桌面端构建不同的布局。
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
                            boxShadow: kBoxShadows, // 使用全局阴影效果
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _buildUserScreenSidebarTools(context),
                          )));
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
  ///
  /// 返回一个包含用户屏幕轮播的SizedBox。
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
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(children: [
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
          ]),
        ),
      ),
    );
  }

  /// 构建用户工具卡片
  ///
  /// 返回一个包含用户工具卡片的AnimatedOpacity。
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
              opacity: 1.0, // 控制可见度的状态
              duration: const Duration(milliseconds: 500),
              child: UserToolsCard(
                onPressed: () {
                  initializeFloating(context, getPageForRoute('fineInformation')!);
                },
                onPressedSecond: () {
                  initializeFloating(context, getPageForRoute('onlineProcessingProgress')!);
                },
                onPressedThird: () {
                  initializeFloating(context, getPageForRoute('userAppeal')!);
                },
                onPressedFourth: () {
                  initializeFloating(context, getPageForRoute('vehicleManagement')!);
                },
                onPressedFifth: () {
                  initializeFloating(context, getPageForRoute('managerPersonalPage')!);
                },
                onPressedSixth: () {
                  initializeFloating(context, getPageForRoute('managerSetting')!);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建头部
  ///
  /// 包含菜单按钮、用户头像和主题切换按钮。
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
            onPressed: () {},
            icon: const Icon(Icons.brightness_6, color: Colors.white),
            tooltip: "切换主题",
          ),
        ],
      ),
    );
  }
}
