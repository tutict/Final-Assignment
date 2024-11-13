library dashboard;

import 'dart:developer';

import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/shared_components/chatting_card.dart';
import 'package:final_assignment_front/shared_components/police_card.dart';
import 'package:final_assignment_front/shared_components/list_profil_image.dart';
import 'package:final_assignment_front/shared_components/add_car_card.dart';
import 'package:final_assignment_front/shared_components/progress_report_card.dart';
import 'package:final_assignment_front/shared_components/project_card.dart';
import 'package:final_assignment_front/shared_components/responsive_builder.dart';
import 'package:final_assignment_front/shared_components/search_field.dart';
import 'package:final_assignment_front/shared_components/selection_button.dart';
import 'package:final_assignment_front/shared_components/case_card.dart';
import 'package:final_assignment_front/shared_components/today_text.dart';
import 'package:final_assignment_front/shared_components/post_card.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
              SliverToBoxAdapter(
                child: _buildHeaderSection(constraints, context),
              ),
              SliverToBoxAdapter(
                child: _buildMainContent(constraints),
              ),
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
        return Column(
          children: [
            _buildProfileSection(),
            _buildProgressSection(Axis.vertical),
            _buildTeamMemberSection(),
            _buildPremiumCard(),
            _buildTaskOverviewSection(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
            ),
            _buildActiveProjectSection(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
            ),
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
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                  ),
                  _buildActiveProjectSection(
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: _buildSideContent(),
            ),
          ],
        );
      },
      desktopBuilder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 2,
              child: _Sidebar(data: controller.getSelectedProject()),
            ),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _buildProgressSection(Axis.horizontal),
                  _buildTaskOverviewSection(
                    crossAxisCount: 4,
                    childAspectRatio: 1.1,
                  ),
                  _buildActiveProjectSection(
                    crossAxisCount: 4,
                    childAspectRatio: 1.1,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: _buildSideContent(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: _buildProfile(data: controller.getProfil()),
    );
  }

  Widget _buildProgressSection(Axis axis) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: _buildProgress(axis: axis),
    );
  }

  Widget _buildTeamMemberSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpacing),
      child: _buildTeamMember(data: controller.getMember()),
    );
  }

  Widget _buildPremiumCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: PoliceCard(onPressed: () {}),
    );
  }

  Widget _buildTaskOverviewSection({
    required int crossAxisCount,
    required double childAspectRatio,
  }) {
    return Obx(() {
      List<CaseCardData> taskList =
          controller.getCaseByType(controller.selectedCaseType.value);
      return _buildTaskOverview(
        data: taskList,
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
      );
    });
  }

  Widget _buildActiveProjectSection({
    required int crossAxisCount,
    required double childAspectRatio,
  }) {
    return _buildActiveProject(
      data: controller.getActiveProject(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
    );
  }

  Widget _buildRecentMessagesSection() {
    return _buildRecentMessages(data: controller.getChatting());
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
                tooltip: "菜单",
              ),
            ),
          const Expanded(child: _Header()),
        ],
      ),
    );
  }

  Widget _buildProgress({Axis axis = Axis.horizontal}) {
    return axis == Axis.horizontal
        ? Row(
            children: [
              Expanded(
                flex: 5,
                child: ProgressCard(
                  data: const ProgressCardData(
                    totalUndone: 10,
                    totalTaskInProress: 2,
                  ),
                  onPressedCheck: () {},
                ),
              ),
              const SizedBox(width: kSpacing / 2),
              const Expanded(
                flex: 4,
                child: ProgressReportCard(
                  data: ProgressReportCardData(
                    title: "案件申诉处理",
                    doneTask: 5,
                    percent: .3,
                    task: 3,
                    undoneTask: 2,
                  ),
                ),
              ),
            ],
          )
        : Column(
            children: [
              ProgressCard(
                data: const ProgressCardData(
                  totalUndone: 10,
                  totalTaskInProress: 2,
                ),
                onPressedCheck: () {},
              ),
              const SizedBox(height: kSpacing / 2),
              const ProgressReportCard(
                data: ProgressReportCardData(
                  title: "案件申诉处理",
                  doneTask: 5,
                  percent: .3,
                  task: 3,
                  undoneTask: 2,
                ),
              ),
            ],
          );
  }

  Widget _buildTaskOverview({
    required List<CaseCardData> data,
    required int crossAxisCount,
    required double childAspectRatio,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: GridView.builder(
        itemCount: data.length + 1,
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
            return _OverviewHeader(
              axis: Axis.horizontal,
              onSelected: (caseType) {
                controller.onCaseTypeSelected(caseType);
              },
            );
          } else {
            return CaseCard(
              data: data[index - 1],
              onPressedMore: () {},
              onPressedTask: () {},
              onPressedContributors: () {},
              onPressedComments: () {},
            );
          }
        },
      ),
    );
  }

  Widget _buildActiveProject({
    required List<ProjectCardData> data,
    required int crossAxisCount,
    required double childAspectRatio,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: _ActiveProjectCard(
        onPressedSeeAll: () {},
        child: GridView.builder(
          itemCount: data.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: kSpacing,
            mainAxisSpacing: kSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            return ProjectCard(data: data[index]);
          },
        ),
      ),
    );
  }

  Widget _buildProfile({required _Profile data}) {
    return _ProfilTile(
      data: data,
      onPressedNotification: () {},
    );
  }

  Widget _buildTeamMember({required List<ImageProvider> data}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TeamMember(
          totalMember: data.length,
          onPressedAdd: () {},
        ),
        const SizedBox(height: kSpacing / 2),
        ListProfilImage(maxImages: 6, images: data),
      ],
    );
  }

  Widget _buildRecentMessages({required List<ChattingCardData> data}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSpacing),
          child: _RecentMessages(onPressedMore: () {}),
        ),
        const SizedBox(height: kSpacing / 2),
        ListView.builder(
          itemCount: data.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return ChattingCard(data: data[index], onPressed: () {});
          },
        ),
      ],
    );
  }
}
