part of '../views/user_screens/user_dashboard.dart';

/// UserDashboardController 管理用户主页的主控制器，包含主要的进入流程、数据处理和界面的控制。
class UserDashboardController extends GetxController with NavigationMixin {
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
  final RxBool _refreshPersonalPage = false.obs;
  final RxString currentDriverName = ''.obs;
  final RxString currentEmail = ''.obs;
  var driverLicenseNumber = RxString('');
  var idCardNumber = RxString('');

  @override
  void onInit() {
    super.onInit();
    _initializeCaseCardData();
    _loadUserFromPrefs();
    loadCredentials();
    _loadTheme(); // Load theme from SharedPreferences
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    currentTheme.value = isDarkMode ? 'Dark' : 'Light';
    _applyTheme();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName') ?? 'Guest';
    final userEmail = prefs.getString('userEmail') ?? 'guest@example.com';
    currentDriverName.value = userName;
    currentEmail.value = userEmail;
    currentUser.value = Profile(
      photo: const AssetImage(ImageRasterPath.avatar1),
      name: userName,
      email: userEmail,
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
      photo: currentUser.value?.photo ?? const AssetImage(ImageRasterPath.avatar1),
      name: name,
      email: email,
    );
    debugPrint('UserDashboardController updated - Name: $name, Email: $email');
    _saveUserToPrefs(name, email);
  }

  Future<void> _saveUserToPrefs(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driverName', name);
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
    currentTheme.value = currentTheme.value == 'Light' ? 'Dark' : 'Light';
    _applyTheme();
    // Save to SharedPreferences to sync with LoginScreen
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isDarkMode', currentTheme.value == 'Dark');
    });
  }

  void toggleChat() {
    isChatExpanded.value = !isChatExpanded.value;
  }

  void _applyTheme() {
    String theme = selectedStyle.value;
    // Check SharedPreferences for isDarkMode to sync with LoginScreen
    SharedPreferences.getInstance().then((prefs) {
      final isDarkMode = prefs.getBool('isDarkMode') ?? false;
      currentTheme.value = isDarkMode ? 'Dark' : 'Light';
    });

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
    debugPrint('Navigating to: $routeName');
    selectedPage.value = getPageForRoute(routeName);
    isShowingSidebarContent.value = true;
  }

  void exitSidebarContent() {
    debugPrint('Exiting sidebar content');
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
    _applyTheme();
  }

  RxBool get refreshPersonalPage => _refreshPersonalPage;
}