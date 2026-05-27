import 'dart:developer' as developer;

import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/core/auth/user_profile_service.dart';
import 'package:final_assignment_front/config/themes/app_theme.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/api/role_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/models/profile.dart';
import 'package:final_assignment_front/utils/components/case_card.dart';
import 'package:final_assignment_front/utils/components/project_card.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';

/// UserDashboardController 管理用户主页的主线控制器，包含主要的进入流程、数据处理和界面的控制。

class UserDashboardController extends GetxController {
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
  final RxBool _refreshPersonalPage = false.obs;
  final RxString currentDriverName = ''.obs;
  final RxString currentEmail = ''.obs;
  var driverLicenseNumber = RxString('');
  var idCardNumber = RxString('');
  final isLoading = true.obs; // Loading state for user data
  final offenseApi = OffenseInformationControllerApi();
  final roleApi = RoleManagementControllerApi();
  Widget? Function(String routeName)? pageResolver;
  Future<void>? _loadUserFuture;
  bool _authRedirectScheduled = false;

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
    final sharedDarkMode = prefs.getBool('isDarkMode');
    if (sharedDarkMode != null) {
      currentTheme.value = sharedDarkMode ? 'Dark' : 'Light';
    } else if (storedTheme != null) {
      currentTheme.value = storedTheme;
    } else {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      currentTheme.value = brightness == Brightness.dark ? 'Dark' : 'Light';
    }
    _applyTheme();
    await prefs.setBool('isDarkMode', currentTheme.value == 'Dark');
    await prefs.setString(
        'userTheme_${selectedStyle.value}', currentTheme.value);
  }

  Future<void> _loadUserFromPrefs() {
    final pendingLoad = _loadUserFuture;
    if (pendingLoad != null) return pendingLoad;

    final load = _loadUserFromPrefsInternal();
    _loadUserFuture = load.whenComplete(() => _loadUserFuture = null);
    return _loadUserFuture!;
  }

  Future<void> _loadUserFromPrefsInternal() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken =
          prefs.getString('jwtToken') ?? prefs.getString('jwt_token');
      final userName = _readableName(
        prefs.getString('userName') ??
            prefs.getString('username') ??
            prefs.getString('displayName'),
        fallback: prefs.getString('email') ?? prefs.getString('userEmail'),
      );
      final userEmail = prefs.getString('userEmail') ??
          prefs.getString('email') ??
          (userName.contains('@') ? userName : null);
      final userRole = prefs.getString('userRole');

      developer.log(
          'Loading user from prefs: jwtToken=$jwtToken, userName=$userName, userEmail=$userEmail, userRole=$userRole');

      if (jwtToken != null && jwtToken.isNotEmpty && userName.isNotEmpty) {
        _authRedirectScheduled = false;
        final resolvedEmail = userEmail ?? userName;
        currentUser.value = Profile(
          photo: const AssetImage(ImageRasterPath.avatar1),
          name: userName,
          email: resolvedEmail,
        );
        currentDriverName.value = userName;
        currentEmail.value = resolvedEmail;
        await prefs.setString('userEmail', resolvedEmail);
        await prefs.setString('email', resolvedEmail);
        await offenseApi.initializeWithJwt();
        await roleApi.initializeWithJwt();
        await _loadUserProfile();
      } else {
        _redirectToLogin(message: '请先登录以访问管理功能');
      }
    } catch (e) {
      developer.log('Error loading user from prefs: $e');
      _redirectToLogin(message: '加载用户信息失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!Get.isRegistered<UserProfileService>()) {
        throw Exception('UserProfileService is not registered');
      }
      final profile = await Get.find<UserProfileService>().getProfile();
      final driverId = profile.driverId;
      if (driverId == null) {
        final resolvedName = _readableName(
          profile.displayName,
          fallback: profile.username,
        );
        final resolvedEmail = profile.email ??
            (currentEmail.value.isNotEmpty
                ? currentEmail.value
                : profile.username);
        updateCurrentUser(resolvedName, resolvedEmail);
        await prefs.setString('userName', resolvedName);
        await prefs.setString('userEmail', resolvedEmail);
        await prefs.setString('authUserId', profile.authUserId.toString());
        await prefs.setString('userId', profile.authUserId.toString());
        developer.log(
          'User has no linked driver profile yet; using account profile only.',
        );
        return;
      }

      final driverApi = DriverInformationControllerApi();
      await driverApi.initializeWithJwt();
      final driver = await driverApi.getDriver(driverId: driverId);
      final resolvedName = _readableName(
        driver?.name ?? profile.driverName ?? profile.displayName,
        fallback: profile.username,
      );
      final resolvedEmail = profile.email ?? currentEmail.value;

      updateCurrentUser(
        resolvedName,
        resolvedEmail,
      );
      driverLicenseNumber.value = driver?.driverLicenseNumber ?? '';
      idCardNumber.value = driver?.idCardNumber ?? '';
      await prefs.setString('userName', resolvedName);
      await prefs.setString('authUserId', profile.authUserId.toString());
      await prefs.setString('userId', profile.authUserId.toString());
      await prefs.setString('driverId', driverId.toString());
      if (resolvedEmail.isNotEmpty) {
        await prefs.setString('userEmail', resolvedEmail);
      }
      developer.log(
        'Updated user info from profile: name=$resolvedName, driverId=$driverId',
      );
    } catch (e) {
      developer.log('Failed to fetch driver data: $e');
      _showErrorSnackBar('无法获取司机信息: $e');
    }
  }

  Future<void> refreshUserData() async {
    developer.log('Refreshing user data');
    await _loadUserFromPrefs();
  }

  void _redirectToLogin({String? message}) {
    if (_authRedirectScheduled) return;
    _authRedirectScheduled = true;
    if (message != null) {
      _showErrorSnackBar(message);
    }
    NavigationHelper.offAllNamed(Routes.login);
  }

  void _showErrorSnackBar(String message) {
    Get.snackbar(
      '错误',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withValues(alpha: 0.9),
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
    final resolvedName = _readableName(name, fallback: email);
    currentDriverName.value = resolvedName;
    currentEmail.value = email;
    currentUser.value = Profile(
      photo:
          currentUser.value?.photo ?? const AssetImage(ImageRasterPath.avatar1),
      name: resolvedName,
      email: email,
    );
    developer.log(
        'UserDashboardController updated - Name: $resolvedName, Email: $email');
    _saveUserToPrefs(resolvedName, email);
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

  void toggleSidebarCollapsed() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
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

  Future<void> setDashboardTheme(String style, String mode) async {
    selectedStyle.value = style;
    currentTheme.value = mode;
    _applyTheme();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', mode == 'Dark');
    await prefs.setString('userTheme_$style', mode);
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
      prefs.setBool('isDarkMode', currentTheme.value == 'Dark');
      prefs.setString('userTheme_${selectedStyle.value}', currentTheme.value);
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
    developer.log('Navigating to: $routeName');
    selectedPage.value = pageResolver?.call(routeName);
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

  String _readableName(String? value, {String? fallback}) {
    final name = value?.trim() ?? '';
    final fallbackName = fallback?.trim() ?? '';
    if (name.isNotEmpty && !_looksCorruptedName(name)) {
      return name;
    }
    if (fallbackName.isNotEmpty && !_looksCorruptedName(fallbackName)) {
      return fallbackName;
    }
    return fallbackName.isNotEmpty ? fallbackName : 'Driver';
  }

  bool _looksCorruptedName(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), '');
    if (compact.isEmpty) return true;
    if (compact.contains('\uFFFD')) return true;

    final questionMarks = '?'.allMatches(compact).length;
    if (questionMarks >= 3 && questionMarks / compact.length > 0.45) {
      return true;
    }

    const mojibakeMarkers = ['Ã', 'Â', 'ä', 'å', 'æ', 'ç', 'è', 'é'];
    final markerCount =
        mojibakeMarkers.where((marker) => compact.contains(marker)).length;
    return markerCount >= 2 && !compact.contains('@');
  }

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
