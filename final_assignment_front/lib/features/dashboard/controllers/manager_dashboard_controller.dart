part of '../views/manager_screens/manager_dashboard_screen.dart';

class DashboardController extends GetxController with NavigationMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final caseCardDataList = <CaseCardData>[].obs;
  var selectedStyle = 'Basic'.obs;
  var currentTheme = 'Light'.obs;
  final Rx<ThemeData> currentBodyTheme = AppTheme.basicLight.obs;
  final selectedCaseType = CaseType.caseManagement.obs;
  final isShowingSidebarContent = false.obs;
  final isScrollingDown = false.obs;
  final isDesktop = false.obs;
  final isSidebarOpen = false.obs;
  final selectedPage = Rx<Widget?>(null);
  final isChatExpanded = true.obs;
  final Rx<Profile?> currentUser = Rx<Profile?>(null); // 更新为 Profile 类型
  // 新增：获取交通违法数据和角色数据
  late Rx<Future<List<OffenseInformation>>> offensesFuture;
  late Rx<Future<List<RoleManagement>>> rolesFuture;

  @override
  void onInit() {
    super.onInit();
    _initializeCaseCardData();
    _loadUserFromPrefs(); // 加载已保存的用户数据
    offensesFuture = Rx<Future<List<OffenseInformation>>>(_fetchAllOffenses());
    rolesFuture = Rx<Future<List<RoleManagement>>>(_fetchAllRoles());
  }

  // 加载保存的用户数据
  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    final userName = prefs.getString('userName');
    final userEmail = prefs.getString('userEmail');
    final userRole = prefs.getString('userRole');

    if (jwtToken != null &&
        userName != null &&
        userEmail != null &&
        userRole != null) {
      currentUser.value = Profile(
        photo: const AssetImage(ImageRasterPath.avatar1), // 默认头像，可根据 API 动态更新
        name: userName,
        email: userEmail,
      );
    } else {
      // 如果没有令牌或用户信息，提示用户登录
      _showErrorSnackBar('请先登录以访问管理功能');
    }
  }

  // 验证 JWT 令牌和角色
  Future<void> _validateTokenAndRole() async {
    final roleApi = RoleManagementControllerApi();
    try {
      final role = await roleApi.getCurrentUserRole();
      if (role != 'ADMIN') {
        throw Exception('权限不足：仅管理员可访问此功能');
      }
    } catch (e) {
      throw Exception('令牌验证失败：$e');
    }
  }

  // 更新当前用户（从 API 获取数据）
  void updateCurrentUser(String name, String email, {ImageProvider? photo}) {
    currentUser.value = Profile(
      photo: photo ?? const AssetImage(ImageRasterPath.avatar1),
      name: name,
      email: email,
    );
    _saveUserToPrefs(name, email, 'ADMIN'); // 保存为 ADMIN 角色
  }

  // 保存用户数据到 SharedPreferences
  Future<void> _saveUserToPrefs(String name, String email, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    await prefs.setString('userRole', role);
  }

  // 获取当前用户
  Profile get currentProfile =>
      currentUser.value ??
      const Profile(
          photo: AssetImage(ImageRasterPath.avatar1),
          name: "Guest",
          email: "guest@example.com");

  // 切换侧边栏状态
  void toggleSidebar() => isSidebarOpen.value = !isSidebarOpen.value;

  // 切换主题
  void toggleBodyTheme() {
    currentTheme.value = currentTheme.value == 'Light' ? 'Dark' : 'Light';
    _applyTheme();
  }

  // 切换 AiChat 状态
  void toggleChat() => isChatExpanded.value = !isChatExpanded.value;

  // 应用主题
  void _applyTheme() {
    String theme = selectedStyle.value;
    ThemeData baseTheme = theme == 'Material'
        ? (currentTheme.value == 'Light'
            ? AppTheme.materialLightTheme
            : AppTheme.materialDarkTheme)
        : (theme == 'Ionic'
            ? (currentTheme.value == 'Light'
                ? AppTheme.ionicLightTheme
                : AppTheme.ionicDarkTheme)
            : (currentTheme.value == 'Light'
                ? AppTheme.basicLight
                : AppTheme.basicDark));

    String fontFamily = theme == 'Basic' ? Font.poppins : 'Helvetica';

    currentBodyTheme.value = baseTheme.copyWith(
      textTheme: baseTheme.textTheme.copyWith(
        labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
          inherit: true,
          fontFamily: fontFamily,
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          color: currentTheme.value == 'Light' ? Colors.black : Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseTheme.colorScheme.primary,
          foregroundColor: baseTheme.colorScheme.onPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          textStyle: TextStyle(
            inherit: true,
            fontFamily: fontFamily,
            fontSize: 16.0,
            fontWeight: FontWeight.normal,
            color: baseTheme.colorScheme.onPrimary,
          ),
        ),
      ),
    );

    Get.changeTheme(currentBodyTheme.value);
  }

  // 打开抽屉
  void openDrawer() => isDesktop.value
      ? isSidebarOpen.value = true
      : scaffoldKey.currentState?.openDrawer();

  // 关闭侧边栏
  void closeSidebar() => isDesktop.value ? isSidebarOpen.value = false : null;

  // 选择案件类型
  void onCaseTypeSelected(CaseType selectedType) =>
      selectedCaseType.value = selectedType;

  // 获取案件数据
  List<CaseCardData> getCaseByType(CaseType type) =>
      caseCardDataList.where((task) => task.type == type).toList();

  // 导航到页面
  void navigateToPage(String routeName) {
    debugPrint('导航至: $routeName');
    selectedPage.value = getPageForRoute(routeName);
    isShowingSidebarContent.value = true;
  }

  // 退出侧边栏内容
  void exitSidebarContent() {
    debugPrint('退出侧边栏内容');
    isShowingSidebarContent.value = false;
    selectedPage.value = null;
  }

  // 构建选中页面内容
  Widget buildSelectedPageContent() =>
      Obx(() => selectedPage.value ?? const SizedBox.shrink());

  // 获取项目信息
  ProjectCardData getSelectedProject() => ProjectCardData(
        percent: .3,
        projectImage: const AssetImage(ImageRasterPath.logo4),
        projectName: "交通违法行为处理管理系统",
        releaseTime: DateTime.now(),
      );

  // 获取活动项目
  List<ProjectCardData> getActiveProject() => [];

  // 获取顾问头像
  List<ImageProvider<Object>> getMember() => const [
        AssetImage(ImageRasterPath.avatar1),
        AssetImage(ImageRasterPath.avatar2),
        AssetImage(ImageRasterPath.avatar3),
        AssetImage(ImageRasterPath.avatar4),
        AssetImage(ImageRasterPath.avatar5),
        AssetImage(ImageRasterPath.avatar6),
      ];

  Future<Map<String, int>> getOffenseTypeDistribution() async {
    try {
      final offenses = await _fetchAllOffenses();
      final Map<String, int> typeCountMap = {};
      for (var o in offenses) {
        final type = o.offenseType ?? 'Unknown Type';
        typeCountMap[type] = (typeCountMap[type] ?? 0) + 1;
      }
      return typeCountMap;
    } catch (e) {
      debugPrint('Error fetching offense distribution: $e');
      return {}; // Return an empty map on error to avoid crashing
    }
  }

  Future<List<OffenseInformation>> _fetchAllOffenses() async {
    try {
      await _validateTokenAndRole();

      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      final listObj = await OffenseInformationControllerApi().apiOffensesGet(
        headers: {'Authorization': 'Bearer $jwtToken'},
      );
      if (listObj == null) return [];
      return listObj.map((item) {
        return OffenseInformation.fromJson(item as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Failed to fetch offense information: $e');
      rethrow;
    }
  }

  Future<List<RoleManagement>> _fetchAllRoles() async {
    try {
      await _validateTokenAndRole();

      final roleApi = RoleManagementControllerApi();
      final roles = await roleApi.apiRolesGet();
      return roles
          .where((role) => role.status == 'Active')
          .toList(); // 使用 status
    } catch (e) {
      debugPrint('Failed to fetch roles: $e');
      rethrow;
    }
  }

  // 显示错误提示
  void _showErrorSnackBar(String message) {
    Get.snackbar('错误', message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white);
  }

  // 更新滑动方向
  void updateScrollDirection(ScrollController scrollController) {
    scrollController.addListener(() {
      isScrollingDown.value = scrollController.position.userScrollDirection ==
          ScrollDirection.reverse;
    });
  }

  // 初始化案件数据
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

  // 设置主题样式
  void setSelectedStyle(String style) {
    selectedStyle.value = style;
    _applyTheme();
  }
}
