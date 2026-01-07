// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:math';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/auth_controller_api.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/api/user_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
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

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

mixin ValidatorMixin {
  String? validateUsername(String? val) {
    if (val == null || val.isEmpty) return 'ç¨æ·é®ç®±ä¸è½ä¸ºç©º';
    final emailRegex =
    RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(val)) return 'è¯·è¾å
¥ææçé®ç®±å°å';
    return null;
  }

  String? validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'å¯ç ä¸è½ä¸ºç©º';
    if (val.length < 5) return 'å¯ç å¤ªç­';
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
    _initializeControllers();
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

  void _initializeControllers() {
    if (!Get.isRegistered<ChatController>()) {
      Get.lazyPut(() => ChatController());
    }
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

  Future<String?> _authUser(LoginData data) async {
    final username = data.name.trim();
    final password = data.password.trim();

    try {
      final result = await authApi.apiAuthLoginPost(
        loginRequest: LoginRequest(username: username, password: password),
      );

      if (result.containsKey('jwtToken')) {
        final jwtToken = result['jwtToken'];
        final decodedJwt = _decodeJwt(jwtToken);
        _userRole = determineRole(decodedJwt['roles'] ?? 'USER');
        final prefs = await SharedPreferences.getInstance();
        await AuthTokenStore.instance.setJwtToken(jwtToken);
        await prefs.setString('userRole', _userRole!);
        await prefs.setString('userName', username);

        final userData = result['user'] ?? {};
        debugPrint('ç»å½è¿åçç¨æ·æ°æ®: $userData');
        final int? userIdFromLogin = userData['userId'];
        String resolvedName = userData['name'] ?? username.split('@').first;
        String resolvedEmail = userData['email'] ?? username;
        debugPrint('æåç userId: $userIdFromLogin, å§å: $resolvedName, é®ç®±: $resolvedEmail');

        String driverName = resolvedName;

        await driverApi.initializeWithJwt();
        debugPrint('Driver API å·²åå§å');
        final userManagementApi = UserManagementControllerApi();
        await userManagementApi.initializeWithJwt();
        debugPrint('UserManagement API å·²åå§å');

        int? userId = userIdFromLogin;
        try {
          final userInfo = await userManagementApi
              .apiUsersSearchUsernameGet(username: username);
          if (userInfo != null) {
            userId = userInfo.userId ?? userId;
            resolvedName =
                userInfo.realName ?? userInfo.username ?? resolvedName;
            resolvedEmail = userInfo.email ?? resolvedEmail;
            debugPrint('éè¿ç¨æ·åæ¥è¯¢è·åç userId: $userId, å§å: $resolvedName');
          }
        } catch (e) {
          debugPrint('éè¿ç¨æ·åæ¥è¯¢ç¨æ·ä¿¡æ¯å¤±è´¥: $e');
        }

        if (userId != null) {
          try {
            final driverInfo =
            await driverApi.apiDriversDriverIdGet(driverId: userId);
            if (driverInfo != null && driverInfo.name != null) {
              driverName = driverInfo.name!;
              debugPrint('ä»æ°æ®åºè·åç driverName: $driverName');
            } else {
              debugPrint('DriverInformation æªæ¾å°æ name ä¸ºç©º');
            }
          } catch (e) {
            if (e is ApiException && e.code == 404) {
              final idempotencyKey = generateIdempotencyKey();
              final newDriverInfo = DriverInformation(
                driverId: userId,
                name: resolvedName,
                contactNumber: '',
                idCardNumber: '',
              );
              await driverApi.apiDriversPost(
                driverInformation: newDriverInfo,
                idempotencyKey: idempotencyKey,
              );
              driverName = resolvedName;
              debugPrint('åå»ºæ°å¸æºè®°å½ï¼driverName: $driverName');
            } else {
              debugPrint('è·å DriverInformation å¤±è´¥: $e');
            }
          }
        } else {
          debugPrint('æ æ³è·å userIdï¼è·³è¿ DriverInformation æ¥è¯¢');
        }

        driverName = driverName.isNotEmpty ? driverName : resolvedName;
        await prefs.setString('driverName', driverName);
        await prefs.setString('userEmail', resolvedEmail);
        if (userId != null) await prefs.setString('userId', userId.toString());

        Get.find<ChatController>().setUserRole(_userRole!);

        debugPrint('ç»å½æå - è§è²: $_userRole, å§å: $driverName, é®ç®±: $resolvedEmail');
        return null;
      }
      return result['message'] ?? 'ç»å½å¤±è´¥';
    } on ApiException catch (e) {
      return _formatErrorMessage(e, 'ç»å½å¤±è´¥');
    } catch (e) {
      debugPrint('ç»å½ä¸­çå¸¸è§å¼å¸¸: $e');
      return 'ç»å½å¼å¸¸: $e';
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    final username = data.name?.trim();
    final password = data.password?.trim();

    if (username == null || password == null) return 'ç¨æ·åæå¯ç ä¸è½ä¸ºç©º';
    if (_hasSentRegisterRequest) return 'æ³¨åè¯·æ±å·²åéï¼è¯·ç­å¾
å¤ç';

    final bool? isCaptchaValid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocalCaptchaMain(),
    );

    if (isCaptchaValid != true) return 'ç¨æ·å·²åæ¶æ³¨åè´¦å·';

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
          final jwtToken = loginResult['jwtToken'];
          final decodedJwt = _decodeJwt(jwtToken);
          _userRole = determineRole(decodedJwt['roles'] ?? 'USER');
          final prefs = await SharedPreferences.getInstance();
          await AuthTokenStore.instance.setJwtToken(jwtToken);
          await prefs.setString('userRole', _userRole!);
          await prefs.setString('userName', username);

          final userData = loginResult['user'] ?? {};
          final int? userId = userData['userId'];
          String resolvedName = userData['name'] ?? username.split('@').first;
          String resolvedEmail = userData['email'] ?? username;

          String driverName = resolvedName;
          if (userId != null) {
            await driverApi.initializeWithJwt();
            final driverInfo = DriverInformation(
              driverId: userId,
              name: resolvedName,
              idCardNumber: '',
              contactNumber: '',
            );
            await driverApi.apiDriversPost(
              driverInformation: driverInfo,
              idempotencyKey: generateIdempotencyKey(),
            );
            final fetchedDriver =
            await driverApi.apiDriversDriverIdGet(driverId: userId);
            driverName = fetchedDriver?.name ?? resolvedName;
            await prefs.setString('driverName', driverName);
            await prefs.setString('userEmail', resolvedEmail);
            await prefs.setString('userId', userId.toString());
            debugPrint('Driver created and fetched name: $driverName');
          }

          Get.find<ChatController>().setUserRole(_userRole!);

          debugPrint(
              'Signup and login successful - Role: $_userRole, Name: $driverName, Email: $resolvedEmail');
          return null;
        }
        return loginResult['message'] ?? 'æ³¨åæåï¼ä½ç»å½å¤±è´¥';
      }
      return registerResult['error'] ?? 'æ³¨åå¤±è´¥ï¼æªç¥éè¯¯';
    } on ApiException catch (e) {
      return _formatErrorMessage(e, 'æ³¨åå¤±è´¥');
    } catch (e) {
      debugPrint('General Exception in signup: $e');
      return 'æ³¨åå¼å¸¸: $e';
    }
  }

  Future<String?> _recoverPassword(String name) async {
    final emailRegex =
    RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(name)) return 'è¯·è¾å
¥ææçé®ç®±å°å';

    final bool? isCaptchaValid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocalCaptchaMain(),
    );

    if (isCaptchaValid != true) return 'å¯ç éç½®å·²åæ¶';

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
            'éç½®å¯ç ',
            style: themeData.textTheme.titleLarge?.copyWith(
              color: themeData.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'è¯·è¾å
¥æ°å¯ç ï¼',
                style: themeData.textTheme.bodyMedium
                    ?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
              ),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'æ°å¯ç ',
                  hintStyle: themeData.textTheme.bodyMedium?.copyWith(
                      color: themeData.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: themeData.colorScheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                        color: themeData.colorScheme.outline.withValues(alpha: 0.3)),
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
                'åæ¶',
                style: themeData.textTheme.labelMedium
                    ?.copyWith(color: themeData.colorScheme.onSurface),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (newPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('æ°å¯ç ä¸è½ä¸ºç©º',
                            style: TextStyle(
                                color:
                                themeData.colorScheme.onErrorContainer))),
                  );
                } else if (newPasswordController.text.length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('å¯ç å¤ªç­',
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
                'ç¡®å®',
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

    if (passwordConfirmed != true) return 'å¯ç éç½®å·²åæ¶';

    final prefs = await SharedPreferences.getInstance();
    final String? jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) return 'è¯·å
ç»å½ä»¥éç½®å¯ç ';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('å¯ç éç½®æåï¼è¯·ä½¿ç¨æ°å¯ç ç»å½',
                style:
                TextStyle(color: themeData.colorScheme.onPrimaryContainer)),
            backgroundColor: themeData.colorScheme.primary,
          ),
        );
        return null;
      } else {
        throw ApiException(
            response.statusCode, 'å¯ç éç½®å¤±è´¥: ${response.statusCode}');
      }
    } on ApiException catch (e) {
      debugPrint('Reset Password Error: $e');
      return _formatErrorMessage(e, 'å¯ç éç½®å¤±è´¥');
    } catch (e) {
      debugPrint('General Exception in reset password: $e');
      return 'å¯ç éç½®å¼å¸¸: $e';
    }
  }

  String _formatErrorMessage(ApiException e, String defaultMessage) {
    switch (e.code) {
      case 400:
        return '$defaultMessage: è¯·æ±éè¯¯ - ${e.message}';
      case 403:
        return '$defaultMessage: æ æé - ${e.message}';
      case 404:
        return '$defaultMessage: æªæ¾å° - ${e.message}';
      case 409:
        return '$defaultMessage: éå¤è¯·æ± - ${e.message}';
      default:
        return '$defaultMessage: æå¡å¨éè¯¯ - ${e.message}';
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
              particleColor: themeData.colorScheme.primary.withValues(alpha: 0.3),
              lineColor: themeData.colorScheme.primary.withValues(alpha: 0.2),
              vsync: this,
            ),
            // Login UI
            FlutterLogin(
              title: 'äº¤éè¿æ³è¡ä¸ºå¤çç®¡çç³»ç»',
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
                  shadowColor: themeData.colorScheme.shadow.withValues(alpha: 0.3),
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
                  highlightColor: themeData.colorScheme.primary.withValues(alpha: 0.9),
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
                    backgroundColor: themeData.colorScheme.error.withValues(alpha: 0.9),
                  ),
                  labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                    color: themeData.colorScheme.onSurfaceVariant,
                    fontSize: 14.0,
                  ),
                  hintStyle: themeData.textTheme.bodyMedium?.copyWith(
                    color:
                    themeData.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 14.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: themeData.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: themeData.colorScheme.outline.withValues(alpha: 0.4),
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
                passwordHint: 'å¯ç ',
                userHint: 'ç¨æ·é®ç®±',
                forgotPasswordButton: 'å¿è®°å¯ç ï¼',
                confirmPasswordHint: 'åæ¬¡è¾å
¥å¯ç ',
                loginButton: 'ç»å½',
                signupButton: 'æ³¨å',
                recoverPasswordButton: 'éç½®å¯ç ',
                recoverCodePasswordDescription: 'è¯·è¾å
¥æ¨çç¨æ·é®ç®±',
                goBackButton: 'è¿å',
                confirmPasswordError: 'å¯ç è¾å
¥ä¸å¹é
',
                confirmSignupSuccess: 'æ³¨åæå',
                confirmRecoverSuccess: 'å¯ç éç½®æå',
                recoverPasswordDescription: 'è¯·è¾å
¥æ¨çç¨æ·é®ç®±ï¼æä»¬å°ä¸ºæ¨éç½®å¯ç ',
                recoverPasswordIntro: 'éç½®å¯ç ',
              ),
              onSubmitAnimationCompleted: () {
                Get.offAllNamed(_userRole == 'ADMIN'
                    ? AppPages.initial
                    : AppPages.userInitial);
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
                tooltip: _isDarkMode ? 'åæ¢å°äº®è²æ¨¡å¼' : 'åæ¢å°æè²æ¨¡å¼',
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
      double currentSpeed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy);
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
      double currentSpeed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy);
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
