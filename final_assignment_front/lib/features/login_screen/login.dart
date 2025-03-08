import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/features/api/auth_controller_api.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/login_request.dart';
import 'package:final_assignment_front/features/model/register_request.dart';
import 'package:final_assignment_front/shared_components/local_captcha_main.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

mixin ValidatorMixin {
  String? validateUsername(String? val) {
    if (val == null || val.isEmpty) return '用户名不能为空';
    return null;
  }

  String? validatePassword(String? val) {
    if (val == null || val.isEmpty) return '密码不能为空';
    if (val.length < 3) return '密码太短';
    return null;
  }
}

class LoginScreen extends StatefulWidget with ValidatorMixin {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late AuthControllerApi authApi;
  late DriverInformationControllerApi driverApi;
  late String? _userRole;
  bool _hasSentRegisterRequest = false;
  final UserDashboardController _userDashboardController =
      Get.find<UserDashboardController>();

  @override
  void initState() {
    super.initState();
    authApi = AuthControllerApi();
    driverApi = DriverInformationControllerApi();
    _userRole = null;
    _hasSentRegisterRequest = false;
    if (!Get.isRegistered<ChatController>()) {
      Get.lazyPut(() => ChatController());
    }
    if (!Get.isRegistered<DashboardController>()) {
      Get.lazyPut(() => DashboardController());
    }
    if (!Get.isRegistered<UserDashboardController>()) {
      Get.lazyPut(() => UserDashboardController());
    }
  }

  static String determineRole(String username) {
    if (username.toLowerCase().endsWith('@admin.com')) {
      return 'ADMIN';
    }
    return 'USER';
  }

  Future<String?> _authUser(LoginData data) async {
    final username = data.name;
    final password = data.password;

    if (username.isEmpty) return '用户邮箱不能为空';
    if (password.isEmpty) return '密码不能为空';

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(username)) {
      return '请输入有效的邮箱地址';
    }

    try {
      final result = await authApi.apiAuthLoginPost(
        loginRequest: LoginRequest(username: username, password: password),
      );

      debugPrint('Login raw result: $result');

      if (result.containsKey('jwtToken')) {
        _userRole = determineRole(username);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwtToken', result['jwtToken']);
        await prefs.setString('userRole', _userRole!);

        final userData = result['user'] ?? {};
        final String name = userData['name'] ?? username.split('@').first;
        final String email = userData['email'] ?? username;

        final DashboardController dashboardController =
            Get.find<DashboardController>();
        dashboardController.updateCurrentUser(name, email);

        final UserDashboardController userDashboardController =
            Get.find<UserDashboardController>();
        userDashboardController.updateCurrentUser(name, email);

        Get.find<ChatController>().setUserRole(_userRole!);

        debugPrint('User Role: $_userRole, Name: $name, Email: $email');
        return null;
      } else {
        return result['message'] ?? '登录失败';
      }
    } on ApiException catch (e) {
      debugPrint('ApiException in login: ${e.message}');
      return '登录失败: ${e.message}';
    } catch (e) {
      debugPrint('General Exception in login: $e');
      return '登录异常: $e';
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    final username = data.name?.trim();
    final password = data.password?.trim();

    if (username == null || username.isEmpty) return '用户邮箱不能为空';
    if (password == null || password.isEmpty) return '密码不能为空';

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(username)) {
      return '请输入有效的邮箱地址';
    }

    if (_hasSentRegisterRequest) {
      return '注册请求已发送，请等待处理';
    }

    final bool? isCaptchaValid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocalCaptchaMain(),
    );

    debugPrint('Signup captcha result: $isCaptchaValid');
    if (isCaptchaValid != true) {
      return '用户已取消注册账号';
    }

    String uniqueKey = generateIdempotencyKey();

    try {
      debugPrint('Sending register request for $username');
      final registerResult = await authApi.apiAuthRegisterPost(
        registerRequest: RegisterRequest(
          username: username,
          password: password,
          idempotencyKey: uniqueKey,
        ),
      );

      debugPrint('Signup raw result: $registerResult');

      if (registerResult['status'] == 'CREATED') {
        _hasSentRegisterRequest = true;

        debugPrint('Sending login request for $username after signup');
        final loginResult = await authApi.apiAuthLoginPost(
          loginRequest: LoginRequest(username: username, password: password),
        );

        debugPrint('Login after signup raw result: $loginResult');

        if (loginResult.containsKey('jwtToken')) {
          _userRole = determineRole(username);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwtToken', loginResult['jwtToken']);
          await prefs.setString('userRole', _userRole!);

          final userData = loginResult['user'] ?? {};
          final int? userId = userData['userId'];
          final String name = userData['name'] ?? username.split('@').first;
          final String email = userData['email'] ?? username;

          if (userId != null) {
            await driverApi.initializeWithJwt();
            final driverInfo = DriverInformation(
              driverId: userId,
              name: name,
              idCardNumber: '',
              contactNumber: '',
            );
            final driverResult = await driverApi.apiDriversPost(
              driverInformation: driverInfo,
              idempotencyKey: generateIdempotencyKey(),
            );
            debugPrint('Driver created: $driverResult');
          }

          final DashboardController dashboardController =
              Get.find<DashboardController>();
          dashboardController.updateCurrentUser(name, email);

          final UserDashboardController userDashboardController =
              Get.find<UserDashboardController>();
          userDashboardController.updateCurrentUser(name, email);

          Get.find<ChatController>().setUserRole(_userRole!);
          debugPrint(
              'User Role after signup and login: $_userRole, Name: $name, Email: $email');
          return null;
        } else {
          return loginResult['message'] ?? '注册成功，但登录失败';
        }
      }
      return registerResult['error'] ?? '注册失败：未知错误';
    } on ApiException catch (e) {
      debugPrint('ApiException in signup: ${e.code} - ${e.message}');
      return '注册失败: ${e.code} - ${e.message}';
    } catch (e) {
      debugPrint('General Exception in signup: $e');
      return '注册异常: $e';
    }
  }

  Future<String?> _recoverPassword(String name) async {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(name)) {
      return '请输入有效的邮箱地址';
    }

    final bool? isCaptchaValid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocalCaptchaMain(),
    );

    debugPrint('Recover captcha result: $isCaptchaValid');
    if (isCaptchaValid != true) {
      debugPrint('Captcha validation failed or cancelled');
      return '密码重置已取消';
    }

    final TextEditingController newPasswordController = TextEditingController();
    final themeData = _userDashboardController.currentBodyTheme.value;
    final isLight = _userDashboardController.currentTheme.value == 'Light';

    final bool? passwordConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Theme(
        data: themeData,
        child: AlertDialog(
          backgroundColor: isLight
              ? themeData.colorScheme.surfaceContainer
              : themeData.colorScheme.surfaceContainerHigh,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Text(
            '重置密码',
            style: themeData.textTheme.titleLarge?.copyWith(
              color: isLight
                  ? themeData.colorScheme.onSurface
                  : themeData.colorScheme.onSurface.withOpacity(0.95),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '请输入新密码：',
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: isLight
                      ? themeData.colorScheme.onSurfaceVariant
                      : themeData.colorScheme.onSurfaceVariant
                          .withOpacity(0.85),
                ),
              ),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '新密码',
                  hintStyle: themeData.textTheme.bodyMedium?.copyWith(
                    color: isLight
                        ? themeData.colorScheme.onSurfaceVariant
                            .withOpacity(0.6)
                        : themeData.colorScheme.onSurfaceVariant
                            .withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: isLight
                      ? themeData.colorScheme.surfaceContainerLowest
                      : themeData.colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                        color: themeData.colorScheme.outline.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                        color: themeData.colorScheme.primary, width: 2.0),
                  ),
                ),
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: isLight
                      ? themeData.colorScheme.onSurface
                      : themeData.colorScheme.onSurface.withOpacity(0.95),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                '取消',
                style: themeData.textTheme.labelMedium?.copyWith(
                  color: isLight
                      ? themeData.colorScheme.onSurface
                      : themeData.colorScheme.onSurface.withOpacity(0.95),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (newPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('新密码不能为空',
                            style: TextStyle(
                                color:
                                    themeData.colorScheme.onErrorContainer))),
                  );
                } else if (newPasswordController.text.length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('密码太短',
                            style: TextStyle(
                                color:
                                    themeData.colorScheme.onErrorContainer))),
                  );
                } else {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.primary,
                foregroundColor: themeData.colorScheme.onPrimary,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)),
              ),
              child: Text(
                '确定',
                style: themeData.textTheme.labelMedium?.copyWith(
                  color: themeData.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (passwordConfirmed != true) {
      debugPrint('Password reset cancelled or invalid');
      return '密码重置已取消';
    }

    final prefs = await SharedPreferences.getInstance();
    final String? jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      debugPrint('No JWT token found in SharedPreferences');
      return '请先登录以重置密码';
    }

    final newPassword = newPasswordController.text.trim();
    final String idempotencyKey = generateIdempotencyKey();

    try {
      final response = await authApi.apiClient.invokeAPI(
        '/api/users/me/password?idempotencyKey=$idempotencyKey',
        'PUT',
        [],
        newPassword,
        {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'text/plain; charset=utf-8',
        },
        {},
        'text/plain',
        ['bearerAuth'],
      );

      debugPrint(
          'Reset password response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        debugPrint('Password reset successful');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('密码重置成功，请使用新密码登录',
                style:
                    TextStyle(color: themeData.colorScheme.onPrimaryContainer)),
            backgroundColor: themeData.colorScheme.primary,
          ),
        );
        return null;
      } else if (response.statusCode == 404) {
        return '用户不存在';
      } else if (response.statusCode == 403) {
        return '密码重置失败：权限不足（可能是令牌无效或过期）';
      } else {
        return '密码重置失败：状态码 ${response.statusCode} - ${response.body}';
      }
    } on ApiException catch (e) {
      debugPrint('ApiException in reset password: ${e.code} - ${e.message}');
      return '密码重置失败: ${e.code} - ${e.message}';
    } catch (e) {
      debugPrint('General Exception in reset password: $e');
      return '密码重置异常: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLight = _userDashboardController.currentTheme.value == 'Light';
      final themeData = _userDashboardController.currentBodyTheme.value;

      return Theme(
        data: themeData,
        child: Stack(
          children: [
            FlutterLogin(
              title: '交通违法行为处理管理系统',
              logo: const AssetImage(ImageRasterPath.logo4),
              onLogin: _authUser,
              onSignup: _signupUser,
              onRecoverPassword: _recoverPassword,
              theme: LoginTheme(
                primaryColor: themeData.colorScheme.primary,
                accentColor: themeData.colorScheme.secondary,
                errorColor: themeData.colorScheme.error,
                pageColorLight: Colors.lightBlueAccent,
                // Light blue for light mode
                buttonTheme: LoginButtonTheme(
                  splashColor: themeData.colorScheme.primaryContainer,
                  backgroundColor: themeData.colorScheme.primary,
                  highlightColor:
                      themeData.colorScheme.primary.withOpacity(0.8),
                  elevation: 9.0,
                  highlightElevation: 6.0,
                ),
                cardTheme: CardTheme(
                  color: isLight
                      ? themeData.colorScheme.surfaceContainerLowest
                      : themeData.colorScheme.surfaceContainerLow,
                  elevation: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 20.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                ),
                titleStyle: themeData.textTheme.headlineMedium?.copyWith(
                  color: isLight
                      ? themeData.colorScheme.onSurface
                      : themeData.colorScheme.onSurface.withOpacity(0.95),
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0,
                ),
                bodyStyle: themeData.textTheme.bodyMedium?.copyWith(
                  color: isLight
                      ? themeData.colorScheme.onSurfaceVariant
                      : themeData.colorScheme.onSurfaceVariant
                          .withOpacity(0.85),
                ),
                textFieldStyle: themeData.textTheme.bodyMedium?.copyWith(
                  color: isLight
                      ? themeData.colorScheme.onSurface
                      : themeData.colorScheme.onSurface.withOpacity(0.95),
                ),
                buttonStyle: themeData.textTheme.labelLarge?.copyWith(
                  color: themeData.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
                inputTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: isLight
                      ? themeData.colorScheme.surfaceContainer
                      : themeData.colorScheme.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  errorStyle: themeData.textTheme.bodySmall?.copyWith(
                    color: themeData.colorScheme.onErrorContainer,
                    backgroundColor:
                        themeData.colorScheme.error.withOpacity(0.9),
                  ),
                  labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                    color: themeData.colorScheme.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                        color: themeData.colorScheme.outline.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                        color: themeData.colorScheme.primary, width: 2.0),
                  ),
                ),
                cardInitialHeight: 300.0,
                cardTopPosition: 250.0,
              ),
              messages: LoginMessages(
                passwordHint: '密码',
                userHint: '用户邮箱',
                forgotPasswordButton: '忘记密码？',
                confirmPasswordHint: '再次输入密码',
                loginButton: '登录',
                signupButton: '注册',
                recoverPasswordButton: '重置密码',
                recoverCodePasswordDescription: '请输入您的用户邮箱',
                goBackButton: '返回',
                confirmPasswordError: '密码输入不匹配',
                confirmSignupSuccess: '注册成功',
                confirmRecoverSuccess: '密码重置成功',
                recoverPasswordDescription: '请输入您的用户邮箱，我们将为您重置密码',
                recoverPasswordIntro: '重置密码',
              ),
              onSubmitAnimationCompleted: () {
                Get.offAllNamed(_userRole == 'ADMIN'
                    ? AppPages.initial
                    : AppPages.userInitial);
              },
            ),
            Positioned(
              bottom: 20.0,
              right: 40.0,
              child: IconButton(
                icon: Icon(
                  isLight ? Icons.dark_mode : Icons.light_mode,
                  color: isLight
                      ? themeData.colorScheme.onSurface
                      : themeData.colorScheme.onSurface.withOpacity(0.95),
                ),
                tooltip: isLight ? '切换到暗色模式' : '切换到亮色模式',
                onPressed: () {
                  _userDashboardController.toggleBodyTheme();
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}
