// ignore_for_file: use_build_context_synchronously
import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'dart:convert';
import 'dart:math';
import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/features/api/auth_controller_api.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/api/user_management_controller_api.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/login_request.dart';
import 'package:final_assignment_front/features/model/register_request.dart';
import 'package:final_assignment_front/shared_components/local_captcha_main.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';

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
    if (val.length < 5) return '密码太短';
    return null;
  }
}

class LoginScreen extends StatefulWidget with ValidatorMixin {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AuthControllerApi authApi;
  late DriverInformationControllerApi driverApi;
  String? _userRole;
  bool _hasSentRegisterRequest = false;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    authApi = AuthControllerApi();
    driverApi = DriverInformationControllerApi();
    _userRole = null;
    _hasSentRegisterRequest = false;
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  Map<String, dynamic> _decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Invalid JWT');
    final payload = base64Url.decode(base64Url.normalize(parts[1]));
    return jsonDecode(utf8.decode(payload));
  }

  static String determineRole(String rolesFromJwt) {
    return rolesFromJwt; // e.g., "USER" or "ADMIN"
  }

  String? _stringValue(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  Future<void> _saveLoginTokens(
    Map<String, dynamic> result,
    SharedPreferences prefs,
    String accessToken,
  ) async {
    await AuthTokenStore.instance.setJwtToken(accessToken);

    final refreshToken = _stringValue(result['refreshToken']);
    if (refreshToken != null) {
      await prefs.setString('refreshToken', refreshToken);
      await prefs.setString('refresh_token', refreshToken);
    }

    final userData = result['user'];
    final authUserId = result['authUserId'] ??
        result['userId'] ??
        (userData is Map ? userData['authUserId'] ?? userData['userId'] : null);
    final driverId = result['driverId'] ??
        (userData is Map ? userData['driverId'] : null);

    if (authUserId != null) {
      final value = authUserId.toString();
      await prefs.setString('authUserId', value);
      await prefs.setString('auth_user_id', value);
      await prefs.setString('userId', value);
    }
    if (driverId != null) {
      final value = driverId.toString();
      await prefs.setString('driverId', value);
      await prefs.setString('driver_id', value);
    }
  }

  Future<String?> _authUser(LoginData data) async {
    final username = data.name.trim();
    final password = data.password.trim();

    try {
      final result = await authApi.login(
        loginRequest: LoginRequest(username: username, password: password),
      );

      final accessToken = _stringValue(result['accessToken'] ?? result['jwtToken']);
      if (accessToken != null) {
        final decodedJwt = _decodeJwt(accessToken);
        _userRole = determineRole(decodedJwt['roles'] ?? 'USER');
        final prefs = await SharedPreferences.getInstance();
        await _saveLoginTokens(result, prefs, accessToken);
        await prefs.setString('userRole', _userRole!);
        await prefs.setString('userName', username);

        final userData = result['user'] ?? {};
        AppLogger.debug('登录返回的用户数据: $userData');
        final int? authUserIdFromLogin =
            userData['authUserId'] ?? userData['userId'];
        final int? driverIdFromLogin =
            userData['driverId'] ?? result['driverId'];
        String resolvedName = userData['name'] ?? username.split('@').first;
        String resolvedEmail = userData['email'] ?? username;
        AppLogger.debug(
            '提取的 authUserId: $authUserIdFromLogin, driverId: $driverIdFromLogin, 姓名: $resolvedName, 邮箱: $resolvedEmail');

        String driverName = resolvedName;

        await driverApi.initializeWithJwt();
        AppLogger.debug('Driver API 已初始化');
        final userManagementApi = UserManagementControllerApi();
        await userManagementApi.initializeWithJwt();
        AppLogger.debug('UserManagement API 已初始化');

        int? authUserId = authUserIdFromLogin;
        int? driverId = driverIdFromLogin;
        try {
          final userInfo =
              await userManagementApi.searchUsersByUsername(username: username);
          if (userInfo != null) {
            authUserId = userInfo.userId ?? authUserId;
            resolvedName =
                userInfo.realName ?? userInfo.username ?? resolvedName;
            resolvedEmail = userInfo.email ?? resolvedEmail;
            AppLogger.debug(
                '通过用户名查询获取的 userId: $authUserId, 姓名: $resolvedName');
          }
        } catch (e) {
          AppLogger.error('通过用户名查询用户信息失败: $e');
        }

        if (driverId == null && authUserId != null) {
          // 此处 authUserId 与 driverId 当前相同，待后端分离后更新
          driverId = authUserId;
        }

        if (driverId != null) {
          try {
            final driverInfo = await driverApi.getDriver(driverId: driverId);
            if (driverInfo != null && driverInfo.name != null) {
              driverName = driverInfo.name!;
              AppLogger.debug('从数据库获取的 driverName: $driverName');
            } else {
              AppLogger.debug('DriverInformation 未找到或 name 为空');
            }
          } catch (e) {
            if (e is ApiException && e.code == 404) {
              final idempotencyKey = generateIdempotencyKey();
              final newDriverInfo = DriverInformation(
                driverId: driverId,
                name: resolvedName,
                contactNumber: '',
                idCardNumber: '',
              );
              await driverApi.createDriver(
                driverInformation: newDriverInfo,
                idempotencyKey: idempotencyKey,
              );
              driverName = resolvedName;
              AppLogger.debug('创建新司机记录，driverName: $driverName');
            } else {
              AppLogger.error('获取 DriverInformation 失败: $e');
            }
          }
        } else {
          AppLogger.debug('无法获取 driverId，跳过 DriverInformation 查询');
        }

        driverName = driverName.isNotEmpty ? driverName : resolvedName;
        await prefs.setString('driverName', driverName);
        await prefs.setString('userEmail', resolvedEmail);
        if (authUserId != null) {
          await prefs.setString('authUserId', authUserId.toString());
          await prefs.setString('auth_user_id', authUserId.toString());
          await prefs.setString('userId', authUserId.toString());
        }
        if (driverId != null) {
          await prefs.setString('driverId', driverId.toString());
          await prefs.setString('driver_id', driverId.toString());
        }

        AppLogger.debug(
            '登录成功 - 角色: $_userRole, authUserId: $authUserId, driverId: $driverId, 姓名: $driverName, 邮箱: $resolvedEmail');
        return null;
      }
      return result['message'] ?? '登录失败';
    } on ApiException catch (e) {
      return _formatErrorMessage(e, '登录失败');
    } catch (e) {
      AppLogger.error('登录中的常规异常: $e');
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
      final registerResult = await authApi.register(
        registerRequest: RegisterRequest(
          username: username,
          password: password,
          idempotencyKey: idempotencyKey,
        ),
      );

      if (registerResult['status'] == 'CREATED') {
        _hasSentRegisterRequest = true;

        final loginResult = await authApi.login(
          loginRequest: LoginRequest(username: username, password: password),
        );

        final accessToken =
            _stringValue(loginResult['accessToken'] ?? loginResult['jwtToken']);
        if (accessToken != null) {
          final decodedJwt = _decodeJwt(accessToken);
          _userRole = determineRole(decodedJwt['roles'] ?? 'USER');
          final prefs = await SharedPreferences.getInstance();
          await _saveLoginTokens(loginResult, prefs, accessToken);
          await prefs.setString('userRole', _userRole!);
          await prefs.setString('userName', username);

          final userData = loginResult['user'] ?? {};
          final int? authUserId = userData['authUserId'] ?? userData['userId'];
          int? driverId = userData['driverId'] ?? loginResult['driverId'];
          String resolvedName = userData['name'] ?? username.split('@').first;
          String resolvedEmail = userData['email'] ?? username;

          String driverName = resolvedName;
          if (driverId == null && authUserId != null) {
            // 此处 authUserId 与 driverId 当前相同，待后端分离后更新
            driverId = authUserId;
          }

          if (driverId != null) {
            await driverApi.initializeWithJwt();
            final driverInfo = DriverInformation(
              driverId: driverId,
              name: resolvedName,
              idCardNumber: '',
              contactNumber: '',
            );
            await driverApi.createDriver(
              driverInformation: driverInfo,
              idempotencyKey: generateIdempotencyKey(),
            );
            final fetchedDriver = await driverApi.getDriver(driverId: driverId);
            driverName = fetchedDriver?.name ?? resolvedName;
            await prefs.setString('driverName', driverName);
            await prefs.setString('userEmail', resolvedEmail);
            if (authUserId != null) {
              await prefs.setString('authUserId', authUserId.toString());
              await prefs.setString('auth_user_id', authUserId.toString());
              await prefs.setString('userId', authUserId.toString());
            }
            await prefs.setString('driverId', driverId.toString());
            await prefs.setString('driver_id', driverId.toString());
            AppLogger.debug('Driver created and fetched name: $driverName');
          }

          AppLogger.debug(
              'Signup and login successful - Role: $_userRole, Name: $driverName, Email: $resolvedEmail');
          return null;
        }
        return loginResult['message'] ?? '注册成功，但登录失败';
      }
      return registerResult['error'] ?? '注册失败：未知错误';
    } on ApiException catch (e) {
      return _formatErrorMessage(e, '注册失败');
    } catch (e) {
      AppLogger.error('General Exception in signup: $e');
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
    final themeData = _isDarkMode ? ThemeData.dark() : ThemeData.light();

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
                          .withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: themeData.colorScheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                        color: themeData.colorScheme.outline
                            .withValues(alpha: 0.3)),
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
                  Get.snackbar(
                    '错误',
                    '新密码不能为空',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red.shade100,
                  );
                } else if (newPasswordController.text.length < 3) {
                  Get.snackbar(
                    '错误',
                    '密码太短',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red.shade100,
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

    final String? jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) return '请先登录以重置密码';

    final newPassword = newPasswordController.text.trim();
    final idempotencyKey = generateIdempotencyKey();

    try {
      final response = await authApi.apiClient.invokeAPI(
        '/api/users/me/password?idempotencyKey=$idempotencyKey',
        'PUT',
        [],
        newPassword,
        {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'text/plain; charset=utf-8'
        },
        {},
        'text/plain',
        ['bearerAuth'],
      );

      if (response.statusCode == 200) {
        Get.snackbar(
          '成功',
          '密码重置成功，请使用新密码登录',
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      } else {
        throw ApiException(
            response.statusCode, '密码重置失败: ${response.statusCode}');
      }
    } on ApiException catch (e) {
      AppLogger.error('Reset Password Error: $e');
      return _formatErrorMessage(e, '密码重置失败');
    } catch (e) {
      AppLogger.error('General Exception in reset password: $e');
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
    final themeData = _isDarkMode ? ThemeData.dark() : ThemeData.light();

    return Theme(
      data: themeData,
      child: Scaffold(
        body: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    themeData.colorScheme.primary.withValues(alpha: 0.1),
                    themeData.colorScheme.secondary.withValues(alpha: 0.3),
                    themeData.colorScheme.surface,
                  ],
                ),
              ),
            ),
            // Particle Effect with Connections
            ConnectedParticleSystem(
              particleColor:
                  themeData.colorScheme.primary.withValues(alpha: 0.3),
              lineColor: themeData.colorScheme.primary.withValues(alpha: 0.2),
              vsync: this,
            ),
            // Login UI
            FlutterLogin(
              title: '交通违法行为处理管理系统',
              logo: const AssetImage('assets/images/raster/logo-5.png'),
              logoTag: 'logo',
              onLogin: _authUser,
              onSignup: _signupUser,
              onRecoverPassword: _recoverPassword,
              userValidator: widget.validateUsername,
              passwordValidator: widget.validatePassword,
              theme: LoginTheme(
                primaryColor: themeData.colorScheme.primary,
                accentColor: themeData.colorScheme.secondary,
                errorColor: themeData.colorScheme.error,
                pageColorLight: Colors.transparent,
                pageColorDark: Colors.transparent,
                cardTheme: CardTheme(
                  color: themeData.colorScheme.surfaceContainer,
                  elevation: 12.0,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 80.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  shadowColor:
                      themeData.colorScheme.shadow.withValues(alpha: 0.3),
                ),
                titleStyle: themeData.textTheme.headlineMedium?.copyWith(
                  color: themeData.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 28.0,
                  letterSpacing: 1.2,
                ),
                bodyStyle: themeData.textTheme.bodyLarge?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                  fontSize: 16.0,
                ),
                textFieldStyle: themeData.textTheme.bodyLarge?.copyWith(
                  color: themeData.colorScheme.onSurface,
                  fontSize: 16.0,
                ),
                buttonStyle: themeData.textTheme.labelLarge?.copyWith(
                  color: themeData.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.0,
                ),
                buttonTheme: LoginButtonTheme(
                  splashColor: themeData.colorScheme.primaryContainer,
                  backgroundColor: themeData.colorScheme.primary,
                  highlightColor:
                      themeData.colorScheme.primary.withValues(alpha: 0.9),
                  elevation: 8.0,
                  highlightElevation: 10.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                inputTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: themeData.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 16.0),
                  prefixIconColor: themeData.colorScheme.onSurfaceVariant,
                  errorStyle: themeData.textTheme.bodySmall?.copyWith(
                    color: themeData.colorScheme.onErrorContainer,
                    backgroundColor:
                        themeData.colorScheme.error.withValues(alpha: 0.9),
                  ),
                  labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                    color: themeData.colorScheme.onSurfaceVariant,
                    fontSize: 14.0,
                  ),
                  hintStyle: themeData.textTheme.bodyMedium?.copyWith(
                    color: themeData.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6),
                    fontSize: 14.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color:
                          themeData.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color:
                          themeData.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: themeData.colorScheme.primary,
                      width: 2.0,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: themeData.colorScheme.error,
                      width: 1.5,
                    ),
                  ),
                ),
                cardInitialHeight: 360.0,
                cardTopPosition: 180.0,
                logoWidth: 140.0,
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
                NavigationHelper.offAllNamed(_userRole == 'ADMIN'
                    ? Routes.dashboard
                    : Routes.userDashboard);
              },
            ),
            // Theme Toggle Button
            Positioned(
              bottom: 32.0,
              right: 32.0,
              child: FloatingActionButton(
                onPressed: _toggleTheme,
                backgroundColor: themeData.colorScheme.primary,
                foregroundColor: themeData.colorScheme.onPrimary,
                elevation: 6.0,
                shape: const CircleBorder(),
                tooltip: _isDarkMode ? '切换到亮色模式' : '切换到暗色模式',
                child: Icon(
                  _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  size: 24.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Particle System with Connected Lines
class ConnectedParticleSystem extends StatefulWidget {
  final Color particleColor;
  final Color lineColor;
  final TickerProvider vsync;

  const ConnectedParticleSystem({
    super.key,
    required this.particleColor,
    required this.lineColor,
    required this.vsync,
  });

  static const double maxDistance = 120.0; // Distance for connecting lines

  @override
  State<ConnectedParticleSystem> createState() =>
      _ConnectedParticleSystemState();
}

class _ConnectedParticleSystemState extends State<ConnectedParticleSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final Random _random = Random();
  static const int particleCount = 50;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: widget.vsync,
      duration: const Duration(seconds: 10),
    )..repeat();
    _particles = List.generate(particleCount, (_) => Particle(_random));
    _controller.addListener(_updateParticles);
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.update();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ParticlePainter(
        particles: _particles,
        particleColor: widget.particleColor,
        lineColor: widget.lineColor,
      ),
      size: Size.infinite,
    );
  }
}

class Particle {
  Offset position;
  Offset velocity;
  double radius;
  final Random random;
  Size? canvasSize; // Store canvas size for boundary checks
  static const double fixedSpeed = 0.5; // Fixed speed for all particles

  Particle(this.random)
      : position = Offset(
          random.nextDouble() * 1000,
          random.nextDouble() * 1000,
        ),
        velocity = Offset(
          cos(random.nextDouble() * 2 * pi) * fixedSpeed,
          sin(random.nextDouble() * 2 * pi) * fixedSpeed,
        ),
        radius = random.nextDouble() * 3 + 2;

  void update() {
    position += velocity;

    // Use canvasSize if available, otherwise default to 1000x1000
    final width = canvasSize?.width ?? 1000;
    final height = canvasSize?.height ?? 1000;

    // Rebound off borders while preserving speed
    if (position.dx <= radius || position.dx >= width - radius) {
      velocity = Offset(-velocity.dx, velocity.dy);
      // Ensure velocity magnitude remains fixedSpeed
      double currentSpeed =
          sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy);
      if (currentSpeed != 0) {
        velocity = Offset(
          velocity.dx * fixedSpeed / currentSpeed,
          velocity.dy * fixedSpeed / currentSpeed,
        );
      }
      // Clamp position to prevent sticking at edges
      position = Offset(
        position.dx.clamp(radius, width - radius),
        position.dy,
      );
    }
    if (position.dy <= radius || position.dy >= height - radius) {
      velocity = Offset(velocity.dx, -velocity.dy);
      // Ensure velocity magnitude remains fixedSpeed
      double currentSpeed =
          sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy);
      if (currentSpeed != 0) {
        velocity = Offset(
          velocity.dx * fixedSpeed / currentSpeed,
          velocity.dy * fixedSpeed / currentSpeed,
        );
      }
      position = Offset(
        position.dx,
        position.dy.clamp(radius, height - radius),
      );
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color particleColor;
  final Color lineColor;

  ParticlePainter({
    required this.particles,
    required this.particleColor,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Update particle canvas size for dynamic boundary checks
    for (var particle in particles) {
      particle.canvasSize = size;
    }

    // Draw lines between nearby particles with dynamic opacity
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final p1 = particles[i];
        final p2 = particles[j];
        final distance = (p1.position - p2.position).distance;
        if (distance < ConnectedParticleSystem.maxDistance) {
          final opacity = 1 - (distance / ConnectedParticleSystem.maxDistance);
          final linePaint = Paint()
            ..color = lineColor.withValues(alpha: opacity * lineColor.a)
            ..strokeWidth = 1.0;
          canvas.drawLine(p1.position, p2.position, linePaint);
        }
      }
    }

    // Draw particles
    final particlePaint = Paint()..color = particleColor;
    for (var particle in particles) {
      canvas.drawCircle(particle.position, particle.radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
