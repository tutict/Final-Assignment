part of '../views/manager_screens/manager_dashboard_screen.dart';

/// DashboardController 管理主控制器，用于处理框架和数据相关的功能。
class DashboardController extends GetxController {
  /// 创建一个 GlobalKey 用于辅助控制主栏。
  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// 案件卡片数据列表，使用 Rx 来监听数据变化。
  var caseCardDataList = <CaseCardData>[].obs;

  /// 选择的案件类型，默认为 caseManagement。
  var selectedCaseType =
      CaseType.caseManagement.obs; // Set default to caseManagement

  // RxBool 用于管理侧边栏显示状态（手机模式下）
  final RxBool isSidebarOpen = false.obs;

  void toggleSidebar() {
    isSidebarOpen.value = !isSidebarOpen.value;
  }

  /// 打开拖拽工具栏。
  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  /// 当选择一个案件类型时，更新 selectedCaseType。
  void onCaseTypeSelected(CaseType selectedType) {
    selectedCaseType.value = selectedType;
  }

  /// 根据案件类型返回相应的案件卡片。
  List<CaseCardData> getCaseByType(CaseType type) {
    return caseCardDataList.where((task) => task.type == type).toList();
  }

  /// 获取用户的资料。
  _Profile getProfil() {
    return const _Profile(
      photo: AssetImage(ImageRasterPath.avatar1), // 设置用户头像
      name: "tutict", // 设置用户名
      email: "tutict@163.com", // 设置用户邮箱
    );
  }

  @override
  void onInit() {
    super.onInit();
    // 添加示例案件
    caseCardDataList.addAll([
      const CaseCardData(
        title: 'Todo Task 1', // 任务标题
        dueDay: 5, // 当前距终止日期还剩余的天数
        totalComments: 10, // 总评论数
        totalContributors: 3, // 总贡献人数
        type: CaseType.caseManagement, // 案件类型，为 caseManagement
        profilContributors: [], // 贡献人员信息
      ),
      const CaseCardData(
        title: 'In Progress Task 1',
        dueDay: 10,
        totalComments: 5,
        totalContributors: 2,
        type: CaseType.caseSearch, // 案件类型，为 caseSearch
        profilContributors: [],
      ),
      const CaseCardData(
        title: 'Done Task 1',
        dueDay: -2,
        totalComments: 3,
        totalContributors: 1,
        type: CaseType.caseAppeal, // 案件类型，为 caseAppeal
        profilContributors: [],
      ),
      // 添加更多案件
    ]);
  }

  /// 获取选中的项目信息。
  ProjectCardData getSelectedProject() {
    return ProjectCardData(
      percent: .3, // 项目完成进度
      projectImage: const AssetImage(ImageRasterPath.logo1), // 项目图标
      projectName: "交通违法行为处理管理系统", // 项目名称
      releaseTime: DateTime.now(), // 项目发布时间
    );
  }

  /// 获取活动项目的列表。
  List<ProjectCardData> getActiveProject() {
    return [
      // 返回活动项目的列表
    ];
  }

  /// 获取顾问图片的列表。
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

  /// 获取聊天卡片数据的列表。
  List<ChattingCardData> getChatting() {
    return const [
      ChattingCardData(
        image: AssetImage(ImageRasterPath.avatar6), // 聊天用户头像
        isOnline: true, // 是否在线
        name: "Samantha", // 聊天用户名称
        lastMessage: "我处理了新的申诉", // 最近的消息
        isRead: false, // 是否已读
        totalUnread: 1, // 未读消息的总数
      ),
    ];
  }
}
