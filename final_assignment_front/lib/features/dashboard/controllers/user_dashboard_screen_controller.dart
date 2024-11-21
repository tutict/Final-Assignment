part of '../views/user_screens/user_dashboard.dart';

/// UserDashboardController 管理用户主页的主控制器，包含了主要的进入流程、数据处理和界面的控制。
class UserDashboardController extends GetxController with NavigationMixin {
  /// 创建一个用于辅助控制主栏的 GlobalKey。
  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// 案件卡片数据列表，使用 Rx 来监听数据变化。
  final caseCardDataList = <CaseCardData>[].obs;

  /// 当前选中的案件类型，默认为 caseManagement。
  final selectedCaseType = CaseType.caseManagement.obs;

  /// 是否显示侧边栏内容的状态。
  final isShowingSidebarContent = false.obs;

  /// 是否在向下滑动的状态。
  final isScrollingDown = false.obs;

  /// 是否在桌面端的状态。
  final isDesktop = false.obs;

  /// 是否打开侧边栏的状态。
  final isSidebarOpen = false.obs;

  /// 当前选择的页面。
  final selectedPage = Rx<Widget?>(null);

  @override
  void onInit() {
    super.onInit();
    _initializeCaseCardData(); // 初始化案件卡片数据
  }

  /// 打开拖拽工具栏。如果是桌面端，便将侧边栏设置为打开状态，否则调用拖拽功能。
  void openDrawer() => isDesktop.value
      ? isSidebarOpen.value = true
      : scaffoldKey.currentState?.openDrawer();

  /// 关闭侧边栏。如果是桌面端，将 isSidebarOpen 设置为 false。
  void closeSidebar() => isDesktop.value ? isSidebarOpen.value = false : null;

  /// 当用户选择一个案件类型时，更新 selectedCaseType。
  void onCaseTypeSelected(CaseType selectedType) =>
      selectedCaseType.value = selectedType;

  /// 根据案件类型返回相应的案件卡片数据。
  List<CaseCardData> getCaseByType(CaseType type) =>
      caseCardDataList.where((task) => task.type == type).toList();

  /// 通过路由名称进入指定的页面，并设置 isShowingSidebarContent 为 true。
  void navigateToPage(String routeName) {
    selectedPage.value = getPageForRoute(routeName);
    isShowingSidebarContent.value = true;  // 点击侧边栏时，显示侧边栏内容
  }

  /// 退出侧边栏内容，将 isShowingSidebarContent 设置为 false，并设置 selectedPage 为 null。
  void exitSidebarContent() {
    isShowingSidebarContent.value = false;  // 退出侧边栏内容时，恢复原来组件
    selectedPage.value = null;
  }

  /// 构建当前选择的页面内容。如果没有选择页面，返回空组件。
  Widget buildSelectedPageContent() {
    return Obx(() {
      final pageContent = selectedPage.value;
      return pageContent ?? const SizedBox.shrink();
    });
  }

  /// 获取用户的资料。
  UserProfile getProfil() => const UserProfile(
    photo: AssetImage(ImageRasterPath.avatar1), // 用户头像
    name: "tutict", // 用户名
    email: "tutict@163.com", // 用户邮箱
  );

  /// 获取当前选中的项目信息。
  ProjectCardData getSelectedProject() => ProjectCardData(
    percent: .3, // 项目完成进度
    projectImage: const AssetImage(ImageRasterPath.logo1), // 项目图标
    projectName: "", // 项目名称
    releaseTime: DateTime.now(), // 项目发布时间
  );

  /// 获取活动项目的列表。
  List<ProjectCardData> getActiveProject() => [];

  /// 获取顾问图片的列表。
  List<ImageProvider> getMember() => const [
    AssetImage(ImageRasterPath.avatar1),
    AssetImage(ImageRasterPath.avatar2),
    AssetImage(ImageRasterPath.avatar3),
    AssetImage(ImageRasterPath.avatar4),
    AssetImage(ImageRasterPath.avatar5),
    AssetImage(ImageRasterPath.avatar6),
  ];

  /// 获取聊天卡片数据的列表。
  List<ChattingCardData> getChatting() => const [
    ChattingCardData(
      image: AssetImage(ImageRasterPath.avatar6), // 聊天用户头像
      isOnline: true, // 是否在线
      name: "Samantha", // 聊天用户名称
      lastMessage: "", // 最近的消息
      isRead: false, // 是否已读
      totalUnread: 1, // 未读消息的总数
    ),
  ];

  /// 更新滑动方向。添加滑动监听器，检测用户是否在向下滑动。
  void updateScrollDirection(ScrollController scrollController) {
    scrollController.addListener(() {
      isScrollingDown.value = scrollController.position.userScrollDirection ==
          ScrollDirection.reverse;
    });
  }

  /// 初始化案件卡片数据。
  void _initializeCaseCardData() {
    caseCardDataList.addAll([
      const CaseCardData(
        title: 'Todo Task 1', // 任务标题
        dueDay: 5, // 距终止日期剩余的天数
        totalComments: 10, // 总评论数
        totalContributors: 3, // 贡献人数
        type: CaseType.caseManagement, // 案件类型
        profilContributors: [], // 贡献者列表
      ),
      const CaseCardData(
        title: 'In Progress Task 1',
        dueDay: 10,
        totalComments: 5,
        totalContributors: 2,
        type: CaseType.caseSearch,
        profilContributors: [],
      ),
      const CaseCardData(
        title: 'Done Task 1',
        dueDay: -2,
        totalComments: 3,
        totalContributors: 1,
        type: CaseType.caseAppeal,
        profilContributors: [],
      ),
    ]);
  }
}
