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

  /// 构建侧边栏
  ///
  /// 此方法根据设备类型返回不同的侧边栏构建结果。
  /// 在桌面模式下返回 null，否则返回一个 Drawer。
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

  /// 构建响应式布局
  ///
  /// 此方法根据设备类型选择不同的布局构建方法。
  /// 对于移动设备和平板设备使用相同的布局，对于桌面设备使用特定的桌面布局。
  Widget _buildResponsiveLayout(BuildContext context) {
    return ResponsiveBuilder(
      mobileBuilder: (context, constraints) => _buildLayout(context),
      tabletBuilder: (context, constraints) => _buildLayout(context),
      desktopBuilder: (context, constraints) =>
          _buildLayout(context, isDesktop: true),
    );
  }

  /// 构建用户仪表板布局
  ///
  /// 此方法构建用户仪表板的具体布局，包括头部、用户屏幕滑动器和用户工具卡片。
  /// 参数 isDesktop 用于指示是否在桌面模式下构建布局。
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

  /// 构建用户屏幕滑动器
  ///
  /// 此方法返回一个固定高度的用户屏幕滑动器组件。
  Widget _buildUserScreenSwiper() {
    return SizedBox(
      height: 250,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kSpacing),
        child: UserScreenSwiper(onPressed: () {}),
      ),
    );
  }

  /// 构建用户工具卡片
  ///
  /// 此方法返回一个固定高度的用户工具卡片组件。
  /// 该组件包含多个 onPressed 方法，用于处理不同的工具卡片点击事件。
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

  /// 构建头部组件
  ///
  /// 此方法根据是否提供了 onPressedMenu 方法来决定是否显示菜单按钮。
  /// 参数 onPressedMenu 是一个可选的回调方法，用于处理菜单按钮的点击事件。
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
