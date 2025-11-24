part of '../views/user_screens/user_dashboard.dart';

/// UserDashboardController 管理用户主页的主线控制器，包含主要的进入流程、数据处理和界面的控制。

class UserDashboardController extends GetxController with NavigationMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final caseCardDataList = <CaseCardData>[].obs;
  var selectedStyle = 'Basic'.obs;
  final currentTheme = 'Light'.obs;
  final Rx<ThemeData> currentBodyTheme = AppTheme.basicLight.obs;
  final selectedCaseType = CaseType.caseManagement.obs;
  final isShowingSidebarContent = false.obs;
  final isScrollingDown = false.obs;
  final isDesktop = false.obs;
  final isSidebarOpen = false.obs;
  final selectedPage = Rx<Widget?>(null);
  final isChatExpanded = false.obs;
  final Rx<Profile?> currentUser = Rx<Profile?>(null);
  final RxBool _refreshPersonalPage = false.obs;
  final RxString currentDriverName = ''.obs;
  final RxString currentEmail = ''.obs;
  var driverLicenseNumber = RxString('');
  var idCardNumber = RxString('');
  final isLoadingUser = true.obs; // Loading state for user data
  final offenseApi = OffenseInformationControllerApi();
  final roleApi = RoleManagementControllerApi();

  @override
  void onInit() {
    super.onInit();
    _initializeCaseCardData();
    _loadUserFromPrefs();
    loadCredentials();
    _loadTheme();
  }

  @override
  void onReady() {
    super.onReady();
    refreshUserData();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTheme = prefs.getString('userTheme_${selectedStyle.value}');
    if (storedTheme != null) {
      currentTheme.value = storedTheme;
      _applyTheme();
    } else {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      currentTheme.value =
          brightness == Brightness.dark ? 'Dark' : 'Light';
      _applyTheme();
      await prefs.setString(
          'userTheme_${selectedStyle.value}', currentTheme.value);
    }
  }

  Future<void> _loadUserFromPrefs() async {
    isLoadingUser.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final userName = prefs.getString('userName');
      final userEmail = prefs.getString('userEmail');
      final userRole = prefs.getString('userRole');

      developer.log(
          'Loading user from prefs: jwtToken=$jwtToken, userName=$userName, userEmail=$userEmail, userRole=$userRole');

      if (jwtToken != null && userName != null && userEmail != null) {
        currentUser.value = Profile(
          photo: const AssetImage(ImageRasterPath.avatar1),
          name: userName,
          email: userEmail,
        );
        currentDriverName.value = userName;
        currentEmail.value = userEmail;
        await offenseApi.initializeWithJwt();
        await roleApi.initializeWithJwt();
        // Fetch driver data to ensure correct name
        await _fetchDriverData();
      } else {
        _showErrorSnackBar('请先登录以访问管理功能');
        _redirectToLogin();
      }
    } catch (e) {
      developer.log('Error loading user from prefs: $e');
      _showErrorSnackBar('加载用户信息失败: $e');
      _redirectToLogin();
    } finally {
      isLoadingUser.value = false;
    }
  }

  Future<void> _fetchDriverData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUsername = prefs.getString('userName');
      if (storedUsername == null || storedUsername.isEmpty) {
        throw Exception('Username not found in storage');
      }
      final userApi = UserManagementControllerApi();
      await userApi.initializeWithJwt();
      final user =
          await userApi.apiUsersSearchUsernameGet(username: storedUsername);
      if (user == null || user.userId == null) {
        throw Exception('User or user ID not found');
      }
      final userId = user.userId!;

      final driverApi = DriverInformationControllerApi();
      await driverApi.initializeWithJwt();
      final driver = await driverApi.apiDriversDriverIdGet(driverId: userId);
      final resolvedName =
          driver?.name ?? user.realName ?? user.username ?? storedUsername;
      final resolvedEmail = user.email ?? currentEmail.value;

      updateCurrentUser(
        resolvedName,
        resolvedEmail,
      );
      driverLicenseNumber.value = driver?.driverLicenseNumber ?? '';
      idCardNumber.value = driver?.idCardNumber ?? '';
      await prefs.setString('userName', resolvedName);
      await prefs.setString('userId', userId.toString());
      if (resolvedEmail.isNotEmpty) {
        await prefs.setString('userEmail', resolvedEmail);
      }
      developer.log('Updated user info from API: name=$resolvedName, id=$userId');
    } catch (e) {
      developer.log('Failed to fetch driver data: $e');
      _showErrorSnackBar('无法获取司机信息: $e');
    }
  }

  Future<void> refreshUserData() async {
    developer.log('Refreshing user data');
    await _loadUserFromPrefs();
  }

  void _redirectToLogin() {
    Get.offAllNamed(Routes.login);
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

  Future<void> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    driverLicenseNumber.value = prefs.getString('driverLicenseNumber') ?? '';
    idCardNumber.value = prefs.getString('idCardNumber') ?? '';
    developer.log(
        'Loaded credentials: driverLicense=${driverLicenseNumber.value}, idCard=${idCardNumber.value}');
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
    developer
        .log('UserDashboardController updated - Name: $name, Email: $email');
    _saveUserToPrefs(name, email);
  }

  Future<void> _saveUserToPrefs(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
  }

  Profile get currentProfile =>
      currentUser.value ??
      const Profile(
        photo: AssetImage(ImageRasterPath.avatar1),
        name: "Guest",
        email: "guest@example.com",
      );

  void toggleSidebar() {
    isSidebarOpen.value = !isSidebarOpen.value;
  }

  void toggleBodyTheme() {
    final newMode = currentTheme.value == 'Light' ? 'Dark' : 'Light';
    currentTheme.value = newMode;
    _applyTheme();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isDarkMode', newMode == 'Dark');
      prefs.setString('userTheme_${selectedStyle.value}', newMode);
    });
  }

  void toggleChat() {
    isChatExpanded.value = !isChatExpanded.value;
  }

  void _applyTheme() {
    String theme = selectedStyle.value;
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
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
    _persistThemeSelection();
  }

  void _persistThemeSelection() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('userTheme_${selectedStyle.value}', currentTheme.value);
    });
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
    developer.log('Navigating to: $routeName');
    selectedPage.value = getPageForRoute(routeName);
    isShowingSidebarContent.value = true;
  }

  void exitSidebarContent() {
    developer.log('Exiting sidebar content');
    isShowingSidebarContent.value = false;
    selectedPage.value = null;
  }

  Widget buildSelectedPageContent() {
    return Obx(() {
      final pageContent = selectedPage.value;
      return pageContent ?? const SizedBox.shrink();
    });
  }

  ProjectCardData getSelectedProject() => ProjectCardData(
        percent: .3,
        projectImage: const AssetImage(ImageRasterPath.logo4),
        projectName: "交通违法行为处理管理系统",
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

  void setSelectedStyle(String style) {
    selectedStyle.value = style;
    _loadTheme();
  }

  RxBool get refreshPersonalPage => _refreshPersonalPage;
}
