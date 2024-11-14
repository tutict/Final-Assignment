part of '../views/user_screens/user_dashboard.dart';

class UserDashboardController extends GetxController with NavigationMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final caseCardDataList = <CaseCardData>[].obs;
  final selectedCaseType = CaseType.caseManagement.obs;
  final isShowingSidebarContent = false.obs;  // 控制是否显示侧边栏内容
  final isScrollingDown = false.obs;
  final isDesktop = false.obs;
  final isSidebarOpen = false.obs;
  final selectedPage = Rx<Widget?>(null);

  @override
  void onInit() {
    super.onInit();
    _initializeCaseCardData();
  }

  void openDrawer() => isDesktop.value
      ? isSidebarOpen.value = true
      : scaffoldKey.currentState?.openDrawer();

  void closeSidebar() => isDesktop.value ? isSidebarOpen.value = false : null;

  void onCaseTypeSelected(CaseType selectedType) =>
      selectedCaseType.value = selectedType;

  List<CaseCardData> getCaseByType(CaseType type) =>
      caseCardDataList.where((task) => task.type == type).toList();

  void navigateToPage(String routeName) {
    selectedPage.value = getPageForRoute(routeName);
    isShowingSidebarContent.value = true;  // 点击侧边栏时，显示侧边栏内容
  }

  void exitSidebarContent() {
    isShowingSidebarContent.value = false;  // 退出侧边栏内容时，恢复原来组件
    selectedPage.value = null;
  }

  Widget buildSelectedPageContent() {
    return Obx(() {
      final pageContent = selectedPage.value;
      return pageContent ?? const SizedBox.shrink();
    });
  }

  UserProfile getProfil() => const UserProfile(
        photo: AssetImage(ImageRasterPath.avatar1),
        name: "tutict",
        email: "tutict@163.com",
      );

  ProjectCardData getSelectedProject() => ProjectCardData(
        percent: .3,
        projectImage: const AssetImage(ImageRasterPath.logo1),
        projectName: "",
        releaseTime: DateTime.now(),
      );

  List<ProjectCardData> getActiveProject() => [];

  List<ImageProvider> getMember() => const [
        AssetImage(ImageRasterPath.avatar1),
        AssetImage(ImageRasterPath.avatar2),
        AssetImage(ImageRasterPath.avatar3),
        AssetImage(ImageRasterPath.avatar4),
        AssetImage(ImageRasterPath.avatar5),
        AssetImage(ImageRasterPath.avatar6),
      ];

  List<ChattingCardData> getChatting() => const [
        ChattingCardData(
          image: AssetImage(ImageRasterPath.avatar6),
          isOnline: true,
          name: "Samantha",
          lastMessage: "",
          isRead: false,
          totalUnread: 1,
        ),
      ];

  void updateScrollDirection(ScrollController scrollController) {
    scrollController.addListener(() {
      isScrollingDown.value = scrollController.position.userScrollDirection ==
          ScrollDirection.reverse;
    });
  }

  void _initializeCaseCardData() {
    caseCardDataList.addAll([
      const CaseCardData(
        title: 'Todo Task 1',
        dueDay: 5,
        totalComments: 10,
        totalContributors: 3,
        type: CaseType.caseManagement,
        profilContributors: [],
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
