import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/dashboard/models/user_profile.dart';
import 'package:final_assignment_front/shared_components/case_card.dart';
import 'package:final_assignment_front/shared_components/chatting_card.dart';
import 'package:final_assignment_front/shared_components/project_card.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserDashboardController extends GetxController {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  var caseCardDataList = <CaseCardData>[].obs;
  var selectedCaseType =
      CaseType.caseManagement.obs; // Set default to caseManagement

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  void onCaseTypeSelected(CaseType selectedType) {
    selectedCaseType.value = selectedType;
  }

  List<CaseCardData> getCaseByType(CaseType type) {
    return caseCardDataList.where((task) => task.type == type).toList();
  }

  // Data
  UserProfile getProfil() {
    return const UserProfile(
      photo: AssetImage(ImageRasterPath.avatar1),
      name: "tutict",
      email: "tutict@163.com",
    );
  }

  @override
  void onInit() {
    super.onInit();
    // ���ʾ������
    caseCardDataList.addAll([
      const CaseCardData(
        title: 'Todo Task 1',
        dueDay: 5,
        totalComments: 10,
        totalContributors: 3,
        type: CaseType.caseManagement,
        // ��Ϊ CaseType
        profilContributors: [],
      ),
      const CaseCardData(
        title: 'In Progress Task 1',
        dueDay: 10,
        totalComments: 5,
        totalContributors: 2,
        type: CaseType.caseSearch,
        // ��Ϊ CaseType
        profilContributors: [],
      ),
      const CaseCardData(
        title: 'Done Task 1',
        dueDay: -2,
        totalComments: 3,
        totalContributors: 1,
        type: CaseType.caseAppeal,
        // ��Ϊ CaseType
        profilContributors: [],
      ),
      // ��Ӹ�������
    ]);
  }

  ProjectCardData getSelectedProject() {
    return ProjectCardData(
      percent: .3,
      projectImage: const AssetImage(ImageRasterPath.logo1),
      projectName: "��ͨΥ����Ϊ�������ϵͳ",
      releaseTime: DateTime.now(),
    );
  }

  List<ProjectCardData> getActiveProject() {
    return [
      // ���ػ��Ŀ���б�
    ];
  }

  List<ImageProvider> getMember() {
    return const [
      AssetImage(ImageRasterPath.avatar1),
      AssetImage(ImageRasterPath.avatar2),
      AssetImage(ImageRasterPath.avatar3),
      AssetImage(ImageRasterPath.avatar4),
      AssetImage(ImageRasterPath.avatar5),
      AssetImage(ImageRasterPath.avatar6),
    ];
  }

  List<ChattingCardData> getChatting() {
    return const [
      ChattingCardData(
        image: AssetImage(ImageRasterPath.avatar6),
        isOnline: true,
        name: "Samantha",
        lastMessage: "�Ҵ������µ�����",
        isRead: false,
        totalUnread: 1,
      ),
    ];
  }
}
