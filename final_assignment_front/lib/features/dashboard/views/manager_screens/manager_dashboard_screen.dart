library manager_dashboard;

import 'dart:developer';
import 'dart:ui';

import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/config/themes/app_theme.dart';
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
import 'package:final_assignment_front/utils/mixins/app_mixins.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

// binding
part '../../bindings/manager_dashboard_binding.dart';

// controller
part '../../controllers/manager_dashboard_controller.dart';

// models
part '../../models/manager_profile.dart';

// components
part '../components/active_project_card.dart';

part '../components/header.dart';

part '../components/overview_header.dart';

part '../components/profile_tile.dart';

part '../components/recent_messages.dart';

part '../components/sidebar.dart';

part '../components/team_member.dart';

class DashboardScreen extends GetView<DashboardController>
    with NavigationMixin {
  const DashboardScreen({super.key});

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
                      child: _Sidebar(data: controller.getSelectedProject()),
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
                      child: _Sidebar(data: controller.getSelectedProject()),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          border: Border(
                              right: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: SingleChildScrollView(
                          child: _buildLayout(context, isDesktop: true),
                        ),
                      ),
                    ),
                    Container(
                      width: screenWidth * 0.3,
                      height: screenHeight,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor.withOpacity(0.9),
                      ),
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
  Widget _buildSideContent(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
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
      ),
    );
  }

  /// 构建整体布局区域
  Widget _buildLayout(BuildContext context, {bool isDesktop = false}) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: kSpacing, vertical: kSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: kSpacing * (kIsWeb || isDesktop ? 2.5 : 3.5)),
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
                    _buildProgressSection(
                        isDesktop ? Axis.horizontal : Axis.vertical, context),
                    _buildTeamMemberSection(context),
                    _buildPremiumCard(context),
                    _buildTaskOverviewSection(
                      context,
                      crossAxisCount: isDesktop ? 4 : 2,
                      childAspectRatio: isDesktop ? 1.1 : 1.2,
                    ),
                    _buildActiveProjectSection(
                      context,
                      crossAxisCount: isDesktop ? 4 : 2,
                      childAspectRatio: isDesktop ? 1.1 : 1.2,
                    ),
                    _buildRecentMessagesSection(context),
                  ],
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  /// 构建用户屏幕侧边工具区域
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
          const Divider(height: 1, thickness: 1),
        ],
      ),
    );
  }

  /// 构建顶部 Header 区域
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
              child: const _Header(),
            ),
            IconButton(
              onPressed: () => log("Chat icon pressed"),
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: "Chat",
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
        child: SizedBox(
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
        ),
      ),
    );
  }

  Widget _buildRecentMessagesSection(BuildContext context) {
    double listHeight = MediaQuery.of(context).size.height * 0.333;
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

  /// 构建侧边栏，使用 AnimatedContainer 实现平滑过渡
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
              child: _Sidebar(data: controller.getSelectedProject()),
            )
          : null,
    );
  }
}
