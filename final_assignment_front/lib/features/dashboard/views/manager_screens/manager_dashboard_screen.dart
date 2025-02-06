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
      // 为保证 Ink 效果正常，将 body 用 Material 作为祖先
      body: Material(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return CustomScrollView(
              slivers: [
                // 头部区域：用 Container 提供一个最小高度
                SliverToBoxAdapter(
                  child: Container(
                      constraints: const BoxConstraints(minHeight: 50),
                      child: _buildHeaderSection(constraints, context)),
                ),
                // 主内容区域：同样用 Container 保证有明确尺寸
                SliverToBoxAdapter(
                  child: Container(
                      constraints: const BoxConstraints(minHeight: 100),
                      child: _buildMainContent(constraints)
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BoxConstraints constraints, BuildContext context) {
    // 请确保此方法内部返回的 widget 不为 null
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
    // 请确保此方法内部返回的 widget 不为 null
    return ResponsiveBuilder(
      mobileBuilder: (context, constraints) {
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
        return SizedBox(
          height: constraints.maxHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: constraints.maxWidth * 0.7,
                child: SingleChildScrollView(
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
              ),
              SizedBox(
                width: constraints.maxWidth * 0.3,
                child: SingleChildScrollView(child: _buildSideContent()),
              ),
            ],
          ),
        );
      },
      desktopBuilder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: constraints.maxWidth * 0.2,
                child: _Sidebar(data: controller.getSelectedProject()),
              ),
              SizedBox(
                width: constraints.maxWidth * 0.5,
                child: SingleChildScrollView(
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
              ),
              SizedBox(
                width: constraints.maxWidth * 0.3,
                child: SingleChildScrollView(child: _buildSideContent()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader({Function()? onPressedMenu}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: Row(
        // 如果 _Header 内部使用了 Expanded，请改为 Flexible 或使用 SingleChildScrollView
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
          // 这里直接使用 _Header（如果 _Header 内部有 Row with Expanded，
          // 请参考 _OverviewHeader 的修改方式，将其改为使用 Flexible 或 mainAxisSize.min）
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _Header(),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 300,
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
          const SizedBox(
            width: 300,
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
            totalMember: controller
                .getMember()
                .length,
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

  /// 任务概览区域，使用 LayoutBuilder 计算 GridView 固定高度
  Widget _buildTaskOverviewSection({
    required int crossAxisCount,
    required double childAspectRatio,
  }) {
    return Obx(() {
      final taskList =
      controller.getCaseByType(controller.selectedCaseType.value);
      // 总 item 数（包含 OverviewHeader 的一个 item）
      final int itemCount = taskList.length + 1;
      return LayoutBuilder(
        builder: (context, constraints) {
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

  /// 活跃项目区域，使用 LayoutBuilder 计算 GridView 固定高度
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
            itemCount: controller
                .getChatting()
                .length,
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
