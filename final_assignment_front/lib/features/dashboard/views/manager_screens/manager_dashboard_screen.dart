// manager_dashboard.dart
library manager_dashboard;

import 'dart:developer';

import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/shared_components/add_car_card.dart';
import 'package:final_assignment_front/shared_components/case_card.dart';
import 'package:final_assignment_front/shared_components/chatting_card.dart';
import 'package:final_assignment_front/shared_components/list_profil_image.dart';
import 'package:final_assignment_front/shared_components/police_card.dart';
import 'package:final_assignment_front/shared_components/post_card.dart';
import 'package:final_assignment_front/shared_components/progress_report_card.dart';
import 'package:final_assignment_front/shared_components/project_card.dart';
import 'package:final_assignment_front/shared_components/responsive_builder.dart';
import 'package:final_assignment_front/shared_components/search_field.dart';
import 'package:final_assignment_front/shared_components/selection_button.dart';
import 'package:final_assignment_front/shared_components/today_text.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// binding
part '../../bindings/manager_dashboard_binding.dart';

// controller
part '../../controllers/manager_dashboard_controller.dart';

// models
part '../../models/manager_profile.dart';

// component
part '../components/active_project_card.dart';

part '../components/header.dart';

part '../components/overview_header.dart';

part '../components/profile_tile.dart';

part '../components/recent_messages.dart';

part '../components/sidebar.dart';

part '../components/team_member.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: controller.scaffoldKey,
      // 移动端显示抽屉，桌面端不显示
      drawer: ResponsiveBuilder.isDesktop(context)
          ? null
          : Drawer(
              child: Padding(
                padding: const EdgeInsets.only(top: kSpacing),
                child: _Sidebar(data: controller.getSelectedProject()),
              ),
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return CustomScrollView(
            slivers: [
              // 头部区域
              SliverToBoxAdapter(
                  child: _buildHeaderSection(constraints, context)),
              // 主内容区域（将 SliverFillRemaining 换为 SliverToBoxAdapter）
              SliverToBoxAdapter(child: _buildMainContent(constraints)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(BoxConstraints constraints, BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: kSpacing * (kIsWeb ? 1 : 2)),
        _buildHeader(onPressedMenu: () => controller.openDrawer()),
        const SizedBox(height: kSpacing / 2),
        const Divider(),
      ],
    );
  }

  Widget _buildMainContent(BoxConstraints constraints) {
    return ResponsiveBuilder(
      mobileBuilder: (context, constraints) {
        // 注意：此处移除了内部的 SingleChildScrollView
        return Column(
          children: [
            _buildProfileSection(),
            _buildProgressSection(Axis.vertical),
            _buildTeamMemberSection(),
            _buildPremiumCard(),
            _buildTaskOverviewSection(crossAxisCount: 2, childAspectRatio: 1.2),
            _buildActiveProjectSection(
                crossAxisCount: 2, childAspectRatio: 1.2),
            _buildRecentMessagesSection(),
          ],
        );
      },
      tabletBuilder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  _buildProgressSection(Axis.horizontal),
                  _buildTaskOverviewSection(
                      crossAxisCount: 3, childAspectRatio: 1.2),
                  _buildActiveProjectSection(
                      crossAxisCount: 3, childAspectRatio: 1.2),
                ],
              ),
            ),
            Expanded(flex: 3, child: _buildSideContent()),
          ],
        );
      },
      desktopBuilder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
                flex: 2,
                child: _Sidebar(data: controller.getSelectedProject())),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _buildProgressSection(Axis.horizontal),
                  _buildTaskOverviewSection(
                      crossAxisCount: 4, childAspectRatio: 1.1),
                  _buildActiveProjectSection(
                      crossAxisCount: 4, childAspectRatio: 1.1),
                ],
              ),
            ),
            Expanded(flex: 3, child: _buildSideContent()),
          ],
        );
      },
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
                icon: const Icon(Icons.menu),
                tooltip: "菜单",
              ),
            ),
          const Expanded(child: _Header()),
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
    );
  }

  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: _ProfilTile(
        data: controller.getProfil(),
        onPressedNotification: () => log("Notification clicked"),
      ),
    );
  }

  Widget _buildProgressSection(Axis axis) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: kSpacing, vertical: kSpacing / 2),
      child: axis == Axis.horizontal
          ? Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Card(
                    child: ListTile(
                      title: const Text("Progress Card"),
                      subtitle: const Text("Undone: 10 | In Progress: 2"),
                      trailing: IconButton(
                          icon: const Icon(Icons.check), onPressed: () {}),
                    ),
                  ),
                ),
                const SizedBox(width: kSpacing / 2),
                const Expanded(
                  flex: 4,
                  child: Card(
                    child: ListTile(
                      title: Text("案件申诉处理"),
                      subtitle: Text("Done: 5 | Undone: 2 | Total: 3"),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Card(
                  child: ListTile(
                    title: const Text("Progress Card"),
                    subtitle: const Text("Undone: 10 | In Progress: 2"),
                    trailing: IconButton(
                        icon: const Icon(Icons.check), onPressed: () {}),
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

  Widget _buildTeamMemberSection() {
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
          ListProfilImage(maxImages: 6, images: controller.getMember()),
        ],
      ),
    );
  }

  Widget _buildPremiumCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: PoliceCard(onPressed: () => log("PoliceCard clicked")),
    );
  }

  /// 修改后的 _buildTaskOverviewSection：计算 GridView 固定高度
  Widget _buildTaskOverviewSection({
    required int crossAxisCount,
    required double childAspectRatio,
  }) {
    return Obx(() {
      final taskList =
          controller.getCaseByType(controller.selectedCaseType.value);
      // 总 item 数（包含放置 OverviewHeader 的第一个 item）
      final int itemCount = taskList.length + 1;
      return LayoutBuilder(
        builder: (context, constraints) {
          // 可用宽度（去掉左右 Padding）
          final availableWidth = constraints.maxWidth - 2 * kSpacing;
          final itemWidth = (availableWidth - (crossAxisCount - 1) * kSpacing) /
              crossAxisCount;
          final itemHeight = itemWidth / childAspectRatio;
          final int rowCount = (itemCount / crossAxisCount).ceil();
          final gridHeight = rowCount * itemHeight + (rowCount - 1) * kSpacing;
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
        },
      );
    });
  }

  /// 修改后的 _buildActiveProjectSection：同样计算 GridView 固定高度
  Widget _buildActiveProjectSection({
    required int crossAxisCount,
    required double childAspectRatio,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: _ActiveProjectCard(
        onPressedSeeAll: () => log("查看所有项目"),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final activeProjects = controller.getActiveProject();
            final int itemCount = activeProjects.length;
            final availableWidth = constraints.maxWidth - 2 * kSpacing;
            final itemWidth =
                (availableWidth - (crossAxisCount - 1) * kSpacing) /
                    crossAxisCount;
            final itemHeight = itemWidth / childAspectRatio;
            final int rowCount = (itemCount / crossAxisCount).ceil();
            final gridHeight =
                rowCount * itemHeight + (rowCount - 1) * kSpacing;
            return SizedBox(
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
                  final data = activeProjects[index];
                  return ProjectCard(data: data);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentMessagesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpacing),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSpacing),
            child: _RecentMessages(
              onPressedMore: () => log("More recent messages clicked"),
            ),
          ),
          const SizedBox(height: kSpacing / 2),
          ListView.builder(
            itemCount: controller.getChatting().length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final data = controller.getChatting()[index];
              return ChattingCard(
                data: data,
                onPressed: () => log("Chat with ${data.name}"),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSideContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProfileSection(),
          const Divider(thickness: 1),
          _buildTeamMemberSection(),
          _buildPremiumCard(),
          const Divider(thickness: 1),
          _buildRecentMessagesSection(),
        ],
      ),
    );
  }
}
