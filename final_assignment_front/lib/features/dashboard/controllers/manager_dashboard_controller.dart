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
  final isChatExpanded = false.obs;
  final Rx<Profile?> currentUser = Rx<Profile?>(null);
  late Rx<Future<List<OffenseInformation>>> offensesFuture;
  final RxString currentDriverName = ''.obs;
  final RxString currentEmail = ''.obs;
  final RxBool _refreshPersonalPage = false.obs;
  final offenseApi = OffenseInformationControllerApi();
  final roleApi = RoleManagementControllerApi();

  @override
  void onInit() {
    super.onInit();
    _initializeCaseCardData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserFromPrefs();
      _loadTheme();
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    currentTheme.value = isDarkMode ? 'Dark' : 'Light';
    _applyTheme();
  }

  void loadAdminData() {
    offensesFuture = Rx<Future<List<OffenseInformation>>>(_fetchAllOffenses());
  }

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
        photo: const AssetImage(ImageRasterPath.avatar1),
        name: userName,
        email: userEmail,
      );
      currentDriverName.value = userName;
      currentEmail.value = userEmail;
      await offenseApi.initializeWithJwt();
      await roleApi.initializeWithJwt();
    } else {
      _showErrorSnackBar('请先登录以访问管理功能');
      _redirectToLogin();
    }
  }

  Future<void> _validateTokenAndRole() async {
    try {
      final role = await roleApi.getCurrentUserRole();
      if (role != 'ADMIN') {
        throw Exception('权限不足：仅管理员可访问此功能');
      }
    } catch (e) {
      _showErrorSnackBar('令牌验证失败：$e');
      _redirectToLogin();
      rethrow;
    }
  }

  void updateCurrentUser(String name, String email) {
    currentDriverName.value = name;
    currentEmail.value = email;
    currentUser.value = Profile(
      photo:
          currentUser.value?.photo ?? const AssetImage(ImageRasterPath.avatar1),
      name: name,
      email: email,
    );
    debugPrint('DashboardController updated - Name: $name, Email: $email');
    _saveUserToPrefs(name, email, 'ADMIN');
  }

  Future<void> _saveUserToPrefs(String name, String email, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    await prefs.setString('userRole', role);
  }

  Profile get currentProfile =>
      currentUser.value ??
      const Profile(
        photo: AssetImage(ImageRasterPath.avatar1),
        name: "Guest",
        email: "guest@example.com",
      );

  void toggleSidebar() => isSidebarOpen.value = !isSidebarOpen.value;

  void toggleBodyTheme() {
    currentTheme.value = currentTheme.value == 'Light' ? 'Dark' : 'Light';
    _applyTheme();
    // Save to SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isDarkMode', currentTheme.value == 'Dark');
    });
  }

  void toggleChat() => isChatExpanded.value = !isChatExpanded.value;

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
          fontFamily: fontFamily,
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          color: baseTheme.colorScheme.onPrimary,
        ),
        bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
          fontFamily: fontFamily,
          fontSize: 16.0,
          color: baseTheme.colorScheme.onSurface,
        ),
        bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
          fontFamily: fontFamily,
          fontSize: 14.0,
          color: baseTheme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseTheme.colorScheme.primary,
          foregroundColor: baseTheme.colorScheme.onPrimary,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          textStyle: TextStyle(
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

  void triggerPersonalPageRefresh() {
    exitSidebarContent();
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
    debugPrint('导航至: $routeName');
    selectedPage.value = getPageForRoute(routeName);
    isShowingSidebarContent.value = true;
  }

  void exitSidebarContent() {
    debugPrint('退出侧边栏内容');
    isShowingSidebarContent.value = false;
    selectedPage.value = null;
  }

  Widget buildSelectedPageContent() =>
      Obx(() => selectedPage.value ?? const SizedBox.shrink());

  ProjectCardData getSelectedProject() => ProjectCardData(
        percent: .3,
        projectImage: const AssetImage(ImageRasterPath.logo4),
        projectName: "交通违法行为处理管理系统",
        releaseTime: DateTime.now(),
      );

  List<ProjectCardData> getActiveProject() => [];

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
      final offenses = await offensesFuture.value;
      final Map<String, int> typeCountMap = {};
      for (var o in offenses) {
        final type = o.offenseType ?? 'Unknown Type';
        typeCountMap[type] = (typeCountMap[type] ?? 0) + 1;
      }
      return typeCountMap;
    } catch (e) {
      debugPrint('Error fetching offense distribution: $e');
      return {};
    }
  }

  Future<List<OffenseInformation>> _fetchAllOffenses() async {
    try {
      await _validateTokenAndRole();
      return await offenseApi.apiOffensesGet();
    } catch (e) {
      debugPrint('Failed to fetch offense information: $e');
      _showErrorSnackBar('无法加载违法行为信息: $e');
      return [];
    }
  }

  void _showErrorSnackBar(String message) {
    Get.snackbar(
      '错误',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void _redirectToLogin() {
    Get.offAllNamed(Routes.login);
  }

  void updateScrollDirection(ScrollController scrollController) {
    scrollController.addListener(() {
      isScrollingDown.value = scrollController.position.userScrollDirection ==
          ScrollDirection.reverse;
    });
  }

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

  void setSelectedStyle(String style) {
    selectedStyle.value = style;
    _applyTheme();
  }

  RxBool get refreshPersonalPage => _refreshPersonalPage;
}
