part of '../views/screens/manager_dashboard_screen.dart';

class DashboardController extends GetxController {
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
  _Profile getProfil() {
    return const _Profile(
      photo: AssetImage(ImageRasterPath.avatar1),
      name: "tutict",
      email: "tutict@163.com",
    );
  }

  @override
  void onInit() {
    super.onInit();
    // 添加示例任务
    caseCardDataList.addAll([
      const CaseCardData(
        title: 'Todo Task 1',
        dueDay: 5,
        totalComments: 10,
        totalContributors: 3,
        type: CaseType.caseManagement,
        // 改为 CaseType
        profilContributors: [],
      ),
      const CaseCardData(
        title: 'In Progress Task 1',
        dueDay: 10,
        totalComments: 5,
        totalContributors: 2,
        type: CaseType.caseSearch,
        // 改为 CaseType
        profilContributors: [],
      ),
      const CaseCardData(
        title: 'Done Task 1',
        dueDay: -2,
        totalComments: 3,
        totalContributors: 1,
        type: CaseType.caseAppeal,
        // 改为 CaseType
        profilContributors: [],
      ),
      // 添加更多任务
    ]);
  }

  ProjectCardData getSelectedProject() {
    return ProjectCardData(
      percent: .3,
      projectImage: const AssetImage(ImageRasterPath.logo1),
      projectName: "交通违法行为处理管理系统",
      releaseTime: DateTime.now(),
    );
  }

  List<ProjectCardData> getActiveProject() {
    return [
      // 返回活动项目的列表
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
        lastMessage: "我处理了新的申诉",
        isRead: false,
        totalUnread: 1,
      ),
    ];
  }
}
