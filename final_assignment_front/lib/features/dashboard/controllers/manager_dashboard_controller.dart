part of '../views/manager_screens/manager_dashboard_screen.dart';

/// DashboardController 管理主控制器，用于处理框架和数据相关的功能。
class DashboardController extends GetxController with NavigationMixin {
  /// 创建一个 GlobalKey 用于辅助控制主栏。
  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// 案件卡片数据列表，使用 Rx 来监听数据变化。
  final caseCardDataList = <CaseCardData>[].obs;

  /// 追踪选中的样式（Material、Ionic 或 Basic）。
  var selectedStyle = 'Basic'.obs;

  /// 追踪当前主题（浅色或深色）。
  var currentTheme = 'Light'.obs;

  /// 当前主体主题，初始化为基本浅色主题。
  final Rx<ThemeData> currentBodyTheme = AppTheme.basicLight.obs;

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

  /// 切换侧边栏的打开/关闭状态。
  void toggleSidebar() {
    isSidebarOpen.value = !isSidebarOpen.value;
  }

  /// 切换浅色和深色主题。
  void toggleBodyTheme() {
    currentTheme.value = currentTheme.value == 'Light' ? 'Dark' : 'Light';
    _applyTheme();
  }

  /// 根据选中的样式和明暗模式应用主题。
  void _applyTheme() {
    String theme = selectedStyle.value;

    // 统一 ThemeData 规范化
    ThemeData baseTheme;
    if (theme == 'Material') {
      baseTheme = currentTheme.value == 'Light'
          ? AppTheme.materialLightTheme
          : AppTheme.materialDarkTheme;
    } else if (theme == 'Ionic') {
      baseTheme = currentTheme.value == 'Light'
          ? AppTheme.ionicLightTheme
          : AppTheme.ionicDarkTheme;
    } else {
      baseTheme = currentTheme.value == 'Light'
          ? AppTheme.basicLight
          : AppTheme.basicDark;
    }

    // 规范化 ThemeData，确保 TextStyle 兼容
    currentBodyTheme.value = baseTheme.copyWith(
      textTheme: baseTheme.textTheme.copyWith(
        labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
          inherit: true,
          fontFamily: 'Poppins', // 如需保持字体一致
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          color: currentTheme.value == 'Light' ? Colors.black : Colors.white,
        ),
      ),
    );

    // 更新全局主题
    Get.changeTheme(currentBodyTheme.value);
  }

  /// 打开拖拽工具栏。如果是桌面端则开启侧边栏，否则调用拖拽功能。
  void openDrawer() => isDesktop.value
      ? isSidebarOpen.value = true
      : scaffoldKey.currentState?.openDrawer();

  /// 关闭侧边栏。如果是桌面端，将 isSidebarOpen 设置为 false。
  void closeSidebar() => isDesktop.value ? isSidebarOpen.value = false : null;

  /// 当用户选择案件类型时，更新 selectedCaseType。
  void onCaseTypeSelected(CaseType selectedType) => selectedCaseType.value = selectedType;

  /// 根据案件类型返回相应的案件卡片数据。
  List<CaseCardData> getCaseByType(CaseType type) =>
      caseCardDataList.where((task) => task.type == type).toList();

  /// 通过路由名称导航到指定页面，并显示侧边栏内容。
  void navigateToPage(String routeName) {
    debugPrint('导航至: $routeName');
    selectedPage.value = getPageForRoute(routeName);
    isShowingSidebarContent.value = true;
  }

  /// 退出侧边栏内容，隐藏内容并清空选中页面。
  void exitSidebarContent() {
    debugPrint('退出侧边栏内容');
    isShowingSidebarContent.value = false;
    selectedPage.value = null;
  }

  /// 构建当前选择的页面内容，若无选中页面则返回空组件。
  Widget buildSelectedPageContent() {
    return Obx(() {
      final pageContent = selectedPage.value;
      return pageContent ?? const SizedBox.shrink();
    });
  }

  /// 获取用户资料。
  _Profile getProfil() => const _Profile(
    photo: AssetImage(ImageRasterPath.avatar1),
    name: "tutict",
    email: "tutict@163.com",
  );

  /// 获取当前选中的项目信息。
  ProjectCardData getSelectedProject() => ProjectCardData(
    percent: .3,
    projectImage: const AssetImage(ImageRasterPath.logo4),
    projectName: "交通违法行为处理管理系统",
    releaseTime: DateTime.now(),
  );

  /// 获取活动项目列表（当前为空）。
  List<ProjectCardData> getActiveProject() => [];

  /// 获取顾问头像列表。
  List<ImageProvider<Object>> getMember() => const [
    AssetImage(ImageRasterPath.avatar1),
    AssetImage(ImageRasterPath.avatar2),
    AssetImage(ImageRasterPath.avatar3),
    AssetImage(ImageRasterPath.avatar4),
    AssetImage(ImageRasterPath.avatar5),
    AssetImage(ImageRasterPath.avatar6),
  ];

  /// 获取聊天卡片数据列表。
  List<ChattingCardData> getChatting() => const [
    ChattingCardData(
      image: AssetImage(ImageRasterPath.avatar6),
      isOnline: true,
      name: "Samantha",
      lastMessage: "我处理了新的申诉",
      isRead: false,
      totalUnread: 1,
    ),
  ];

  /// 更新滑动方向，通过监听滚动控制器检测是否向下滚动。
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
        title: '待办任务 1',
        dueDay: 5,
        totalComments: 10,
        totalContributors: 3,
        type: CaseType.caseManagement,
        profilContributors: [],
      ),
      const CaseCardData(
        title: '进行中任务 1',
        dueDay: 10,
        totalComments: 5,
        totalContributors: 2,
        type: CaseType.caseSearch,
        profilContributors: [],
      ),
      const CaseCardData(
        title: '已完成任务 1',
        dueDay: -2,
        totalComments: 3,
        totalContributors: 1,
        type: CaseType.caseAppeal,
        profilContributors: [],
      ),
    ]);
  }

  /// 设置选中的主题样式（Material、Ionic 或 Basic）并应用。
  void setSelectedStyle(String style) {
    selectedStyle.value = style;
    _applyTheme();
  }
}