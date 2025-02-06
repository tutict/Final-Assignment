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

part '../components/header.dart'; // Make sure that the Row in _Header is wrapped with a parent that provides a finite width.
part '../components/overview_header.dart';

part '../components/profile_tile.dart';

part '../components/recent_messages.dart';

part '../components/sidebar.dart';

part '../components/team_member.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to obtain the screen dimensions.
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      key: controller.scaffoldKey,
      // Show Drawer only if not desktop.
      drawer: ResponsiveBuilder.isDesktop(context)
          ? null
          : Drawer(
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 16), // 16 pixels top padding
                child: _Sidebar(data: controller.getSelectedProject()),
              ),
            ),
      // The body fills the full screen height.
      body: SizedBox(
        height: screenHeight,
        child: Material(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Ensure the content fills at least the screen height.
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: screenHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section with a minimum height of 50.
                      Container(
                        constraints: const BoxConstraints(minHeight: 50),
                        child: _buildHeaderSection(context, screenWidth),
                      ),
                      // Main Content Section with a minimum height of 100.
                      Container(
                        constraints: const BoxConstraints(minHeight: 100),
                        child: _buildMainContent(
                            context, screenWidth, screenHeight),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Builds the header section.
  Widget _buildHeaderSection(BuildContext context, double screenWidth) {
    return Column(
      children: [
        const SizedBox(height: 32), // Fixed 32 pixels vertical spacing.
        _buildHeader(
          onPressedMenu: () => controller.openDrawer(),
          screenWidth: screenWidth,
        ),
        const SizedBox(height: 8), // Fixed 8 pixels vertical spacing.
        const Divider(), // Default Divider.
      ],
    );
  }

  /// Builds the header row.
  /// A Container with a fixed width (screenWidth minus horizontal paddings) wraps the Row.
  Widget _buildHeader(
      {Function()? onPressedMenu, required double screenWidth}) {
    // Calculate available width: screenWidth - 2 * kSpacing.
    final double availableWidth = screenWidth - 2 * kSpacing;
    return Container(
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
          // Expanded widget ensures the inner content takes up the remaining space.
          const Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _Header(), // Defined in part '../components/header.dart'
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
    );
  }

  /// Builds the main content area.
  Widget _buildMainContent(
      BuildContext context, double screenWidth, double screenHeight) {
    return ResponsiveBuilder(
      mobileBuilder: (context, constraints) {
        return Column(
          children: [
            _buildProfileSection(context),
            _buildProgressSection(Axis.vertical, context),
            _buildTeamMemberSection(context),
            _buildPremiumCard(context),
            _buildTaskOverviewSection(context,
                crossAxisCount: 2, childAspectRatio: 1.2),
            _buildActiveProjectSection(context,
                crossAxisCount: 2, childAspectRatio: 1.2),
            _buildRecentMessagesSection(context),
          ],
        );
      },
      tabletBuilder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side: 70% of the screen width.
            SizedBox(
              height: screenHeight,
              width: screenWidth * 0.7,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProgressSection(Axis.horizontal, context),
                    _buildTaskOverviewSection(context,
                        crossAxisCount: 3, childAspectRatio: 1.2),
                    _buildActiveProjectSection(context,
                        crossAxisCount: 3, childAspectRatio: 1.2),
                  ],
                ),
              ),
            ),
            // Right side: 30% of the screen width.
            SizedBox(
              height: screenHeight,
              width: screenWidth * 0.3,
              child: SingleChildScrollView(child: _buildSideContent(context)),
            ),
          ],
        );
      },
      desktopBuilder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left sidebar: 20% of screen width.
            SizedBox(
              height: screenHeight,
              width: screenWidth * 0.2,
              child: _Sidebar(data: controller.getSelectedProject()),
            ),
            // Middle content: 50% of screen width.
            SizedBox(
              height: screenHeight,
              width: screenWidth * 0.5,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProgressSection(Axis.horizontal, context),
                    _buildTaskOverviewSection(context,
                        crossAxisCount: 4, childAspectRatio: 1.1),
                    _buildActiveProjectSection(context,
                        crossAxisCount: 4, childAspectRatio: 1.1),
                  ],
                ),
              ),
            ),
            // Right side: 30% of screen width.
            SizedBox(
              height: screenHeight,
              width: screenWidth * 0.3,
              child: SingleChildScrollView(child: _buildSideContent(context)),
            ),
          ],
        );
      },
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
            // Use a fraction of the screen width and height for the card dimensions.
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
    // Calculate gridHeight based on screen height fractions.
    double gridHeight;
    if (crossAxisCount == 2) {
      gridHeight = MediaQuery.of(context).size.height * 1.44; // approx 1042/720
    } else if (crossAxisCount == 3) {
      gridHeight = MediaQuery.of(context).size.height * 0.94; // approx 676/720
    } else {
      gridHeight = MediaQuery.of(context).size.height * 0.78; // approx 562/720
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
    double listHeight = MediaQuery.of(context).size.height *
        0.333; // about one-third of the screen height
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

  Widget _buildSideContent(BuildContext context) {
    return SingleChildScrollView(
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
