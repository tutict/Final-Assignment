import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/core/auth/role_utils.dart';
import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/config/themes/app_theme.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/api/role_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/models/profile.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/shared/utils/error_handler.dart';
import 'package:final_assignment_front/shared_components/case_card.dart';
import 'package:final_assignment_front/shared_components/project_card.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';

class ManagerDashboardController extends GetxController {
  final caseCardDataList = <CaseCardData>[].obs;
  var selectedStyle = 'Basic'.obs;
  final currentTheme = 'Light'.obs;
  final Rx<ThemeData> currentBodyTheme = AppTheme.basicLight.obs;
  final selectedCaseType = CaseType.caseManagement.obs;
  final isShowingSidebarContent = false.obs;
  final isScrollingDown = false.obs;
  final isDesktop = false.obs;
  final isSidebarOpen = false.obs;
  final isSidebarCollapsed = false.obs;
  final selectedPage = Rx<Widget?>(null);
  final isChatExpanded = false.obs;
  final Rx<Profile?> currentUser = Rx<Profile?>(null);
  late Rx<Future<List<OffenseInformation>>> offensesFuture;
  final RxString currentDriverName = ''.obs;
  final RxString currentEmail = ''.obs;
  final RxString currentRole = 'USER'.obs;
  final RxString errorMessage = ''.obs;
  final RxBool _refreshPersonalPage = false.obs;
  final offenseApi = OffenseInformationControllerApi();
  final roleApi = RoleManagementControllerApi();
  Widget? Function(String routeName)? pageResolver;

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
    final themeKey = 'dashboardTheme_${selectedStyle.value}';
    final storedTheme = prefs.getString(themeKey);
    final sharedDarkMode = prefs.getBool('isDarkMode');
    if (sharedDarkMode != null) {
      currentTheme.value = sharedDarkMode ? 'Dark' : 'Light';
    } else if (storedTheme != null) {
      currentTheme.value = storedTheme;
    } else {
      final systemBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      currentTheme.value =
          systemBrightness == Brightness.dark ? 'Dark' : 'Light';
    }
    _applyTheme();
    await prefs.setBool('isDarkMode', currentTheme.value == 'Dark');
    await prefs.setString(themeKey, currentTheme.value);
  }

  void loadAdminData() {
    offensesFuture = Rx<Future<List<OffenseInformation>>>(_fetchAllOffenses());
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    final userName = prefs.getString('userName');
    final userEmail = prefs.getString('userEmail');
    final userRole = prefs.getString('roles') ?? prefs.getString('userRole');

    if (jwtToken != null &&
        userName != null &&
        userEmail != null &&
        userRole != null &&
        RoleUtils.canAccessAdminDashboard(userRole)) {
      currentUser.value = Profile(
        photo: const AssetImage(ImageRasterPath.avatar1),
        name: userName,
        email: userEmail,
      );
      currentDriverName.value = userName;
      currentEmail.value = userEmail;
      currentRole.value = RoleUtils.preferredRole(userRole);
      await offenseApi.initializeWithJwt();
      await roleApi.initializeWithJwt();
    } else {
      ErrorHandler.showError(
        Exception('Login required to access manager features'),
        fallbackMessage: 'Login required to access manager features',
      );
      _redirectToLogin();
    }
  }

  Future<void> _validateTokenAndRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roleSource =
          prefs.getString('roles') ?? prefs.getString('userRole');
      if (!RoleUtils.canAccessAdminDashboard(roleSource)) {
        throw Exception('Manager role is required');
      }
    } catch (e) {
      ErrorHandler.showError(e, fallbackMessage: '令牌验证失败，请重新登录');
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
    AppLogger.debug(
        'ManagerDashboardController updated - Name: $name, Email: $email');
    _saveUserToPrefs(name, email, currentRole.value);
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

  bool get isSuperAdmin => RoleUtils.isSuperAdminRole(currentRole.value);

  bool get isBusinessAdmin => RoleUtils.isAdminRole(currentRole.value);

  String get roleDisplayName => isSuperAdmin ? '超级管理员端' : '管理端';

  void toggleSidebar() => isSidebarOpen.value = !isSidebarOpen.value;

  void toggleSidebarCollapsed() =>
      isSidebarCollapsed.value = !isSidebarCollapsed.value;

  void toggleBodyTheme() {
    final newMode = currentTheme.value == 'Light' ? 'Dark' : 'Light';
    currentTheme.value = newMode;
    _applyTheme();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isDarkMode', newMode == 'Dark');
      prefs.setString('dashboardTheme_${selectedStyle.value}', newMode);
    });
  }

  Future<void> setDashboardTheme(String style, String mode) async {
    selectedStyle.value = style;
    currentTheme.value = mode;
    _applyTheme();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', mode == 'Dark');
    await prefs.setString('dashboardTheme_$style', mode);
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

    String? fontFamily;

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
          color: baseTheme.colorScheme.onSurface.withValues(alpha: 0.7),
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
    _persistThemeSelection();
  }

  void _persistThemeSelection() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isDarkMode', currentTheme.value == 'Dark');
      prefs.setString(
          'dashboardTheme_${selectedStyle.value}', currentTheme.value);
    });
  }

  void triggerPersonalPageRefresh() {
    exitSidebarContent();
  }

  void openDrawer() => isSidebarOpen.value = true;

  void closeSidebar() => isDesktop.value ? isSidebarOpen.value = false : null;

  void onCaseTypeSelected(CaseType selectedType) =>
      selectedCaseType.value = selectedType;

  List<CaseCardData> getCaseByType(CaseType type) =>
      caseCardDataList.where((task) => task.type == type).toList();

  void navigateToPage(String routeName) {
    AppLogger.debug('导航至: $routeName');
    selectedPage.value = pageResolver?.call(routeName);
    isShowingSidebarContent.value = true;
  }

  void exitSidebarContent() {
    AppLogger.debug('退出侧边栏内容');
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
      errorMessage.value = ErrorHandler.extractMessage(e);
      rethrow;
    }
  }

  Future<List<OffenseInformation>> _fetchAllOffenses() async {
    try {
      await _validateTokenAndRole();
      return await offenseApi.listOffenses();
    } catch (e) {
      errorMessage.value = ErrorHandler.extractMessage(e);
      rethrow;
    }
  }

  void _redirectToLogin() {
    NavigationHelper.offAllNamed(Routes.login);
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
    _loadTheme();
  }

  RxBool get refreshPersonalPage => _refreshPersonalPage;
}
