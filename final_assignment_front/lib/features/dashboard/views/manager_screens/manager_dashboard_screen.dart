// manager_dashboard.dart
library manager_dashboard;

import 'dart:developer';

import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/shared_components/case_card.dart';
import 'package:final_assignment_front/shared_components/chatting_card.dart';
import 'package:final_assignment_front/shared_components/list_profil_image.dart';
import 'package:final_assignment_front/shared_components/police_card.dart';
import 'package:final_assignment_front/shared_components/post_card.dart';
import 'package:final_assignment_front/shared_components/project_card.dart';
import 'package:final_assignment_front/shared_components/responsive_builder.dart';
import 'package:final_assignment_front/shared_components/search_field.dart';
import 'package:final_assignment_front/shared_components/selection_button.dart';
import 'package:final_assignment_front/shared_components/today_text.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// For brevity, the following parts are defined in this file. In your project you can split them.
// binding
part '../../bindings/manager_dashboard_binding.dart';

// controller
part '../../controllers/manager_dashboard_controller.dart';

// models
part '../../models/manager_profile.dart';

// components
part '../components/active_project_card.dart';

part '../components/header.dart'; // 其中 _Header 内部已用局部常量 kSpacing 等。
part '../components/overview_header.dart';

part '../components/profile_tile.dart';

part '../components/recent_messages.dart';

part '../components/sidebar.dart';

part '../components/team_member.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取屏幕尺寸
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    // 计算顶栏总高度（例如：上边距 32 + header 行 50 + 下边距 15 + Divider 高度 1）
    const double kHeaderTotalHeight = 32 + 50 + 15 + 1;

    return Scaffold(
      key: controller.scaffoldKey,
      // 将顶栏固定在 appBar 中
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kHeaderTotalHeight),
        child: _buildHeaderSection(context, screenWidth),
      ),
      // 非桌面端通过抽屉显示侧边栏
      drawer: ResponsiveBuilder.isDesktop(context)
          ? null
          : Drawer(
              child: Padding(
                padding: const EdgeInsets.only(top: kSpacing),
                child: _Sidebar(data: controller.getSelectedProject()),
              ),
            ),
      // 主体内容不再包含顶栏，直接展示主体部分
      body: Material(
        child: ResponsiveBuilder(
          mobileBuilder: (context, constraints) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileSection(context),
                  _buildProgressSection(Axis.vertical, context),
                  _buildTeamMemberSection(context),
                  _buildPremiumCard(context),
                  _buildTaskOverviewSection(
                    context,
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                  ),
                  _buildActiveProjectSection(
                    context,
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                  ),
                  _buildRecentMessagesSection(context),
                ],
              ),
            );
          },
          tabletBuilder: (context, constraints) {
            // 平板端布局
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 固定侧边栏
                SizedBox(
                  width: screenWidth * 0.3,
                  child: _Sidebar(data: controller.getSelectedProject()),
                ),
                // 主要内容区域
                SizedBox(
                  width: screenWidth * 0.7,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildProfileSection(context),
                        _buildProgressSection(Axis.horizontal, context),
                        _buildTaskOverviewSection(
                          context,
                          crossAxisCount: 3,
                          childAspectRatio: 1.2,
                        ),
                        _buildActiveProjectSection(
                          context,
                          crossAxisCount: 3,
                          childAspectRatio: 1.2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          desktopBuilder: (context, constraints) {
            // 桌面端布局
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧固定侧边栏，占 20% 宽度
                SizedBox(
                  width: screenWidth * 0.2,
                  height: screenHeight,
                  child: _Sidebar(data: controller.getSelectedProject()),
                ),
                // 中间滚动内容，占 50% 宽度
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildProgressSection(Axis.horizontal, context),
                        _buildTaskOverviewSection(
                          context,
                          crossAxisCount: 4,
                          childAspectRatio: 1.1,
                        ),
                        _buildActiveProjectSection(
                          context,
                          crossAxisCount: 4,
                          childAspectRatio: 1.1,
                        ),
                      ],
                    ),
                  ),
                ),
                // 右侧固定聊天或侧边内容栏，占 30% 宽度
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
    );
  }

  /// 构建顶栏区域（包含上下间距和分割线）
  Widget _buildHeaderSection(BuildContext context, double screenWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 32), // 固定上边距 32
        _buildHeader(
          onPressedMenu: () => controller.openDrawer(),
          screenWidth: screenWidth,
        ),
        const SizedBox(height: 15), // 固定下边距 15
        const Divider(), // 分割线
      ],
    );
  }

  /// 构建顶栏的内容行
  Widget _buildHeader({
    Function()? onPressedMenu,
    required double screenWidth,
  }) {
    // 计算可用宽度：屏幕宽度减去左右内边距（2 * kSpacing）
    final double availableWidth = screenWidth - 2 * kSpacing;
    return SizedBox(
      height: 50, // 固定高度 50 像素，确保内部内容完整显示
      child: Container(
        width: availableWidth,
        padding: const EdgeInsets.symmetric(horizontal: kSpacing),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (onPressedMenu != null)
              IconButton(
                onPressed: onPressedMenu,
                icon: const Icon(Icons.menu),
                tooltip: "菜单",
              ),
            // 中间部分采用 Expanded 和水平滚动，确保内容不会溢出
            const Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _Header(), // 该组件定义在 part '../components/header.dart'
              ),
            ),
            IconButton(
              onPressed: () => log("Chat icon pressed"),
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: "Chat",
            ),
            IconButton(
              onPressed: () => log("Theme toggle pressed"),
              icon: const Icon(Icons.brightness_6),
              tooltip: "切换主题",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: _ProfilTile(
        data: controller.getProfil(),
        onPressedNotification: () => log("Notification clicked"),
      ),
    );
  }

  Widget _buildProgressSection(Axis axis, BuildContext context) {
    if (axis == Axis.horizontal) {
      return Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: kSpacing, vertical: kSpacing / 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.234,
              height: MediaQuery.of(context).size.height * 0.278,
              child: Card(
                child: ListTile(
                  title: const Text("Progress Card"),
                  subtitle: const Text("Undone: 10 | In Progress: 2"),
                  trailing: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {},
                  ),
                ),
              ),
            ),
            const SizedBox(width: kSpacing / 2),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.234,
              height: MediaQuery.of(context).size.height * 0.278,
              child: const Card(
                child: ListTile(
                  title: Text("案件申诉处理"),
                  subtitle: Text("Done: 5 | Undone: 2 | Total: 3"),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: kSpacing, vertical: kSpacing / 2),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text("Progress Card"),
                subtitle: const Text("Undone: 10 | In Progress: 2"),
                trailing: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () {},
                ),
              ),
            ),
            const SizedBox(height: kSpacing / 2),
            const Card(
              child: ListTile(
                title: Text("案件申诉处理"),
                subtitle: Text("Done: 5 | Undone: 2 | Total: 3"),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTeamMemberSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TeamMember(
            totalMember: controller.getMember().length,
            onPressedAdd: () => log("Add member clicked"),
          ),
          const SizedBox(height: kSpacing / 2),
          ListProfilImage(
            maxImages: 6,
            images: controller.getMember(),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: PoliceCard(onPressed: () => log("PoliceCard clicked")),
    );
  }

  Widget _buildTaskOverviewSection(BuildContext context,
      {required int crossAxisCount, required double childAspectRatio}) {
    double gridHeight;
    if (crossAxisCount == 2) {
      gridHeight = MediaQuery.of(context).size.height * 1.44;
    } else if (crossAxisCount == 3) {
      gridHeight = MediaQuery.of(context).size.height * 0.94;
    } else {
      gridHeight = MediaQuery.of(context).size.height * 0.78;
    }
    return Obx(() {
      final taskList =
          controller.getCaseByType(controller.selectedCaseType.value);
      final int itemCount = taskList.length + 1;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: kSpacing),
        child: SizedBox(
          height: gridHeight,
          child: GridView.builder(
            itemCount: itemCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: kSpacing,
              mainAxisSpacing: kSpacing,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) {
              if (index == 0) {
                return OverviewHeader(
                  axis: Axis.horizontal,
                  onSelected: (caseType) =>
                      controller.onCaseTypeSelected(caseType),
                );
              } else {
                return CaseCard(
                  data: taskList[index - 1],
                  onPressedMore: () {},
                  onPressedTask: () {},
                  onPressedContributors: () {},
                  onPressedComments: () {},
                );
              }
            },
          ),
        ),
      );
    });
  }

  Widget _buildActiveProjectSection(BuildContext context,
      {required int crossAxisCount, required double childAspectRatio}) {
    double gridHeight;
    if (crossAxisCount == 2) {
      gridHeight = MediaQuery.of(context).size.height * 1.44;
    } else if (crossAxisCount == 3) {
      gridHeight = MediaQuery.of(context).size.height * 0.94;
    } else {
      gridHeight = MediaQuery.of(context).size.height * 0.78;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: _ActiveProjectCard(
        onPressedSeeAll: () => log("查看所有项目"),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: gridHeight,
              child: GridView.builder(
                itemCount: controller.getActiveProject().length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: kSpacing,
                  mainAxisSpacing: kSpacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemBuilder: (context, index) {
                  final data = controller.getActiveProject()[index];
                  return ProjectCard(data: data);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentMessagesSection(BuildContext context) {
    double listHeight =
        MediaQuery.of(context).size.height * 0.333; // 大约屏幕高度的1/3
    final chattingList = controller.getChatting();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSpacing),
            child: _RecentMessages(
              onPressedMore: () => log("More recent messages clicked"),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: listHeight,
            child: ListView.builder(
              itemCount: chattingList.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final data = chattingList[index];
                return ChattingCard(
                  data: data,
                  onPressed: () => log("Chat with ${data.name}"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建右侧侧边/聊天内容区域
  /// 这里可根据需要决定是否允许内部滚动（此处独立于中间内容滚动）
  Widget _buildSideContent(BuildContext context) {
    return SingleChildScrollView(
      // 如果希望此区域固定高度且内容全部展示，可去掉 SingleChildScrollView
      child: Column(
        children: [
          _buildProfileSection(context),
          const Divider(thickness: 1),
          _buildTeamMemberSection(context),
          _buildPremiumCard(context),
          const Divider(thickness: 1),
          _buildRecentMessagesSection(context),
        ],
      ),
    );
  }
}
