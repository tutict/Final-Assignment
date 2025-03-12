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
    if (val == null || val.isEmpty) return '用户邮箱不能为空';
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(val)) return '请输入有效的邮箱地址';
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
  String? _userRole;
  bool _hasSentRegisterRequest = false;
  final UserDashboardController _userDashboardController =
      Get.find<UserDashboardController>();
  final DashboardController _dashboardController =
      Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    authApi = AuthControllerApi();
    driverApi = DriverInformationControllerApi();
    _userRole = null;
    _hasSentRegisterRequest = false;
    _initializeControllers();
  }

  void _initializeControllers() {
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
    return username.toLowerCase().endsWith('@admin.com') ? 'ADMIN' : 'USER';
  }

  Future<String?> _authUser(LoginData data) async {
    final username = data.name.trim();
    final password = data.password.trim();

    try {
      final result = await authApi.apiAuthLoginPost(
        loginRequest: LoginRequest(username: username, password: password),
      );

      if (result.containsKey('jwtToken')) {
        _userRole = determineRole(username);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwtToken', result['jwtToken']);
        await prefs.setString('userRole', _userRole!);

        final userData = result['user'] ?? {};
        final int? userId = userData['userId'];
        final String name = userData['name'] ?? username.split('@').first;
        final String email = userData['email'] ?? username;

        // Fetch driver name if userId is available
        String driverName = name;
        if (userId != null) {
          await driverApi.initializeWithJwt();
          final driverInfo = await driverApi.apiDriversDriverIdGet(
              driverId: userId.toString());
          driverName = driverInfo?.name ?? name;
          await prefs.setString(
              'driverName', driverName); // Store for ProfilTile
          debugPrint('Fetched driver name after login: $driverName');
        }

        _dashboardController.updateCurrentUser(driverName, email);
        _userDashboardController.updateCurrentUser(driverName, email);
        Get.find<ChatController>().setUserRole(_userRole!);

        debugPrint(
            'Login successful - Role: $_userRole, Name: $driverName, Email: $email');
        return null;
      }
      return result['message'] ?? '登录失败';
    } on ApiException catch (e) {
      return _formatErrorMessage(e, '登录失败');
    } catch (e) {
      debugPrint('General Exception in login: $e');
      return '登录异常: $e';
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    final username = data.name?.trim();
    final password = data.password?.trim();

    if (username == null || password == null) return '用户名或密码不能为空';
    if (_hasSentRegisterRequest) return '注册请求已发送，请等待处理';

    final bool? isCaptchaValid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocalCaptchaMain(),
    );

    if (isCaptchaValid != true) return '用户已取消注册账号';

    final idempotencyKey = generateIdempotencyKey();

    try {
      final registerResult = await authApi.apiAuthRegisterPost(
        registerRequest: RegisterRequest(
          username: username,
          password: password,
          idempotencyKey: idempotencyKey,
        ),
      );

      if (registerResult['status'] == 'CREATED') {
        _hasSentRegisterRequest = true;

        final loginResult = await authApi.apiAuthLoginPost(
          loginRequest: LoginRequest(username: username, password: password),
        );

        if (loginResult.containsKey('jwtToken')) {
          _userRole = determineRole(username);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwtToken', loginResult['jwtToken']);
          await prefs.setString('userRole', _userRole!);

          final userData = loginResult['user'] ?? {};
          final int? userId = userData['userId'];
          final String name = userData['name'] ?? username.split('@').first;
          final String email = userData['email'] ?? username;

          // Fetch or set driver name
          String driverName = name;
          if (userId != null) {
            await driverApi.initializeWithJwt();
            final driverInfo = DriverInformation(
              driverId: userId,
              name: name,
              idCardNumber: '',
              contactNumber: '',
            );
            await driverApi.apiDriversPost(
              driverInformation: driverInfo,
              idempotencyKey: generateIdempotencyKey(),
            );
            final fetchedDriver = await driverApi.apiDriversDriverIdGet(
                driverId: userId.toString());
            driverName = fetchedDriver?.name ?? name;
            await prefs.setString(
                'driverName', driverName); // Store for ProfilTile
            debugPrint('Driver created and fetched name: $driverName');
          }

          _dashboardController.updateCurrentUser(driverName, email);
          _userDashboardController.updateCurrentUser(driverName, email);
          Get.find<ChatController>().setUserRole(_userRole!);
          debugPrint(
              'Signup and login successful - Role: $_userRole, Name: $driverName, Email: $email');
          return null;
        }
        return loginResult['message'] ?? '注册成功，但登录失败';
      }
      return registerResult['error'] ?? '注册失败：未知错误';
    } on ApiException catch (e) {
      return _formatErrorMessage(e, '注册失败');
    } catch (e) {
      debugPrint('General Exception in signup: $e');
      return '注册异常: $e';
    }
  }

  Future<String?> _recoverPassword(String name) async {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(name)) return '请输入有效的邮箱地址';

    final bool? isCaptchaValid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocalCaptchaMain(),
    );

    if (isCaptchaValid != true) return '密码重置已取消';

    final TextEditingController newPasswordController = TextEditingController();
    final themeData = _userDashboardController.currentBodyTheme.value;

    final bool? passwordConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Theme(
        data: themeData,
        child: AlertDialog(
          backgroundColor: themeData.colorScheme.surfaceContainer,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Text(
            '重置密码',
            style: themeData.textTheme.titleLarge?.copyWith(
              color: themeData.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '请输入新密码：',
                style: themeData.textTheme.bodyMedium
                    ?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
              ),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '新密码',
                  hintStyle: themeData.textTheme.bodyMedium?.copyWith(
                      color: themeData.colorScheme.onSurfaceVariant
                          .withOpacity(0.6)),
                  filled: true,
                  fillColor: themeData.colorScheme.surfaceContainerLowest,
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
                style: themeData.textTheme.bodyMedium
                    ?.copyWith(color: themeData.colorScheme.onSurface),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                '取消',
                style: themeData.textTheme.labelMedium
                    ?.copyWith(color: themeData.colorScheme.onSurface),
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

    if (passwordConfirmed != true) return '密码重置已取消';

    final prefs = await SharedPreferences.getInstance();
    final String? jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) return '请先登录以重置密码';

    final newPassword = newPasswordController.text.trim();
    final idempotencyKey = generateIdempotencyKey();

    try {
      final response = await authApi.apiClient.invokeAPI(
        '/api/users/me/password?idempotencyKey=$idempotencyKey',
        'PUT',
        [],
        newPassword,
        // Send new password as plain text body
        {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'text/plain; charset=utf-8'
        },
        {},
        'text/plain',
        ['bearerAuth'],
      );

      if (response.statusCode == 200) {
        // Optionally update SharedPreferences or controllers if backend returns data
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('密码重置成功，请使用新密码登录',
                style:
                    TextStyle(color: themeData.colorScheme.onPrimaryContainer)),
            backgroundColor: themeData.colorScheme.primary,
          ),
        );
        return null; // Success
      } else {
        throw ApiException(
            response.statusCode, '密码重置失败: ${response.statusCode}');
      }
    } on ApiException catch (e) {
      debugPrint('Reset Password Error: $e');
      return _formatErrorMessage(e, '密码重置失败');
    } catch (e) {
      debugPrint('General Exception in reset password: $e');
      return '密码重置异常: $e';
    }
  }

  String _formatErrorMessage(ApiException e, String defaultMessage) {
    switch (e.code) {
      case 400:
        return '$defaultMessage: 请求错误 - ${e.message}';
      case 403:
        return '$defaultMessage: 无权限 - ${e.message}';
      case 404:
        return '$defaultMessage: 未找到 - ${e.message}';
      case 409:
        return '$defaultMessage: 重复请求 - ${e.message}';
      default:
        return '$defaultMessage: 服务器错误 - ${e.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
                buttonTheme: LoginButtonTheme(
                  splashColor: themeData.colorScheme.primaryContainer,
                  backgroundColor: themeData.colorScheme.primary,
                  highlightColor:
                      themeData.colorScheme.primary.withOpacity(0.8),
                  elevation: 9.0,
                  highlightElevation: 6.0,
                ),
                cardTheme: CardTheme(
                  color: themeData.colorScheme.surfaceContainer,
                  elevation: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 20.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                ),
                titleStyle: themeData.textTheme.headlineMedium?.copyWith(
                  color: themeData.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0,
                ),
                bodyStyle: themeData.textTheme.bodyMedium
                    ?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
                textFieldStyle: themeData.textTheme.bodyMedium
                    ?.copyWith(color: themeData.colorScheme.onSurface),
                buttonStyle: themeData.textTheme.labelLarge?.copyWith(
                  color: themeData.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
                inputTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: themeData.colorScheme.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  errorStyle: themeData.textTheme.bodySmall?.copyWith(
                    color: themeData.colorScheme.onErrorContainer,
                    backgroundColor:
                        themeData.colorScheme.error.withOpacity(0.9),
                  ),
                  labelStyle: themeData.textTheme.bodyMedium
                      ?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
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
                  _userDashboardController.currentTheme.value == 'Light'
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: themeData.colorScheme.onSurface,
                ),
                tooltip: _userDashboardController.currentTheme.value == 'Light'
                    ? '切换到暗色模式'
                    : '切换到亮色模式',
                onPressed: () {
                  _userDashboardController.toggleBodyTheme();
                  _dashboardController.toggleBodyTheme();
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}
