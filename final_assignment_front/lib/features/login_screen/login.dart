// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/config/themes/app_theme.dart';
import 'package:final_assignment_front/core/auth/role_utils.dart';
import 'package:final_assignment_front/core/auth/user_profile_service.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/core/theme/app_colors.dart';
import 'package:final_assignment_front/core/theme/theme_controller.dart';
import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/core/validation/credentials.dart';
import 'package:final_assignment_front/features/api/auth_controller_api.dart';
import 'package:final_assignment_front/features/model/login_request.dart';
import 'package:final_assignment_front/features/model/register_request.dart';
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';
import 'package:final_assignment_front/utils/components/local_captcha_main.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

String generateIdempotencyKey() => const Uuid().v4();

enum _AuthMode { login, signup, recover }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late AuthControllerApi authApi;
  late ThemeController _theme;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _userRole;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  _AuthMode _mode = _AuthMode.login;

  @override
  void initState() {
    super.initState();
    authApi = AuthControllerApi();
    _theme = Get.find<ThemeController>();
    _userRole = null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = base64Url.decode(base64Url.normalize(parts[1]));
      return jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('JWT 解码失败: $e');
      return null;
    }
  }

  static String determineRole(Object? rolesFromJwt) {
    return RoleUtils.preferredRole(rolesFromJwt);
  }

  String? _stringValue(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  Future<void> _saveLoginTokens(
    Map<String, dynamic> result,
    String accessToken,
    String username, {
    Object? jwtRoles,
  }) async {
    await AuthTokenStore.instance.setJwtToken(accessToken);

    final refreshToken = _stringValue(result['refreshToken']);
    await AuthTokenStore.instance.setRefreshToken(refreshToken);

    final data = result['success'] == true && result['data'] is Map
        ? Map<String, dynamic>.from(result['data'] as Map)
        : result;
    final userData = data['user'];
    final resolvedUsername = _stringValue(data['username'] ??
            (userData is Map ? userData['username'] : null)) ??
        username;
    final resolvedEmail = _stringValue(
            data['email'] ?? (userData is Map ? userData['email'] : null)) ??
        (resolvedUsername.contains('@') ? resolvedUsername : username);

    // UserProfileService.persistFromLoginResponse is the single writer of
    // every profile preference (username/userName, email/userEmail,
    // authUserId/auth_user_id/userId, driverId/driver_id, roles, userRole,
    // displayName, phoneNumber, driverName). The login screen no longer
    // hand-writes the same keys a second time. We inject the resolved
    // username/email (so typed-in values backfill an absent response body) and
    // the JWT roles (the authoritative role source, since the response body
    // may omit roles) so the service persists them in one pass.
    await Get.find<UserProfileService>().persistFromLoginResponse({
      ...data,
      'username': resolvedUsername,
      'email': resolvedEmail,
      if (jwtRoles != null) 'roleCodes': jwtRoles,
    });
  }

  Future<String?> _authUser(String username, String password) async {
    try {
      final result = await authApi.login(
        loginRequest: LoginRequest(username: username, password: password),
      );

      final accessToken =
          _stringValue(result['accessToken'] ?? result['jwtToken']);
      if (accessToken != null) {
        final decodedJwt = _decodeJwt(accessToken);
        if (decodedJwt == null) {
          return '登录返回数据异常，请重试';
        }
        _userRole = determineRole(decodedJwt['roles'] ?? 'USER');
        await _saveLoginTokens(
          result,
          accessToken,
          username,
          jwtRoles: decodedJwt['roles'],
        );

        final profile = await Get.find<UserProfileService>().getProfile();
        AppLogger.debug(
          '登录成功 - 角色: $_userRole, authUserId: ${profile.authUserId}, driverId: ${profile.driverId}',
        );
        return null;
      }
      return result['message']?.toString() ?? '登录失败';
    } on AppException catch (e) {
      return _formatErrorMessage(e, '登录失败');
    } catch (e) {
      AppLogger.error('登录异常: $e');
      return '登录失败，请稍后重试';
    }
  }

  Future<String?> _signupUser(String username, String password) async {
    final bool? isCaptchaValid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocalCaptchaMain(),
    );

    if (isCaptchaValid != true) return '用户已取消注册';

    try {
      final registerResult = await authApi.register(
        registerRequest: RegisterRequest(
          username: username,
          password: password,
          idempotencyKey: generateIdempotencyKey(),
        ),
      );

      if (registerResult['status'] == 'CREATED') {
        final loginResult = await authApi.login(
          loginRequest: LoginRequest(username: username, password: password),
        );

        final accessToken =
            _stringValue(loginResult['accessToken'] ?? loginResult['jwtToken']);
        if (accessToken != null) {
          final decodedJwt = _decodeJwt(accessToken);
          if (decodedJwt == null) {
            return '注册成功，但登录返回数据异常';
          }
          _userRole = determineRole(decodedJwt['roles'] ?? 'USER');
          await _saveLoginTokens(
            loginResult,
            accessToken,
            username,
            jwtRoles: decodedJwt['roles'],
          );

          final profile = await Get.find<UserProfileService>().getProfile();
          AppLogger.debug(
            '注册并登录成功 - 角色: $_userRole, authUserId: ${profile.authUserId}, driverId: ${profile.driverId}',
          );
          return null;
        }
        return loginResult['message']?.toString() ?? '注册成功，但自动登录失败';
      }
      return registerResult['error']?.toString() ?? '注册失败：未知错误';
    } on AppException catch (e) {
      return _formatErrorMessage(e, '注册失败');
    } catch (e) {
      AppLogger.error('注册异常: $e');
      return '注册失败，请稍后重试';
    }
  }

  Future<String?> _recoverPassword(String name) async {
    // Password reset is an authenticated flow (it reuses the current session's
    // JWT). Fail fast with a clear message instead of walking an unauthenticated
    // user through captcha + a new-password dialog only to dead-end them.
    final String? jwtToken = await AuthTokenStore.instance.getJwtToken();
    if (jwtToken == null) {
      return '重置密码需要先登录。如忘记密码，请联系管理员重置。';
    }

    final bool? isCaptchaValid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocalCaptchaMain(),
    );

    if (isCaptchaValid != true) return '密码重置已取消';

    final TextEditingController newPasswordController = TextEditingController();
    final themeData = _buildTheme();

    // Capture the chosen password inside the dialog so we never read a
    // disposed controller afterwards.
    final bool? passwordConfirmed;
    String? chosenPassword;
    try {
      passwordConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => Theme(
          data: themeData,
          child: AlertDialog(
            title: const Text('重置密码'),
            content: TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '新密码',
                prefixIcon: Icon(Icons.lock_reset_rounded),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  if (newPasswordController.text.trim().length <
                      kMinPasswordLength) {
                    Get.snackbar(
                      '错误',
                      kPasswordTooShortMessage,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }
                  chosenPassword = newPasswordController.text.trim();
                  Navigator.pop(context, true);
                },
                child: const Text('确定'),
              ),
            ],
          ),
        ),
      );
    } finally {
      newPasswordController.dispose();
    }

    if (passwordConfirmed != true) return '密码重置已取消';

    final newPassword = chosenPassword!;

    try {
      await authApi.updateCurrentPassword(
        newPassword: newPassword,
        idempotencyKey: generateIdempotencyKey(),
      );

      return null;
    } on AppException catch (e) {
      AppLogger.error('重置密码失败: $e');
      return _formatErrorMessage(e, '密码重置失败');
    } catch (e) {
      AppLogger.error('重置密码异常: $e');
      return '密码重置失败，请稍后重试';
    }
  }

  String _formatErrorMessage(AppException e, String defaultMessage) {
    final message = e.message;
    switch (e.statusCode) {
      case 401:
        return '用户名或密码错误';
      case 400:
        return '$defaultMessage: 请求参数错误 - $message';
      case 423:
        return '账户已被锁定，请联系管理员';
      case 429:
        return '尝试过于频繁，请稍后再试';
      case 503:
        return '服务暂时不可用，请稍后重试';
      case 403:
        return '$defaultMessage: 无权限 - $message';
      case 404:
        return '$defaultMessage: 未找到 - $message';
      case 409:
        final lower = message.toLowerCase();
        if (lower.contains('username already exists')) {
          return '该邮箱已注册，请直接登录';
        }
        if (lower.contains('duplicated') || lower.contains('duplicate')) {
          return '注册请求已在处理中，请稍后再试';
        }
        return '$defaultMessage: 请求冲突 - $message';
      default:
        return '$defaultMessage: 服务器错误 - $message';
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final username = _emailController.text.trim();
    final password = _passwordController.text.trim();
    String? errorMessage;

    try {
      switch (_mode) {
        case _AuthMode.login:
          errorMessage = await _authUser(username, password);
          if (errorMessage == null) _navigateAfterAuth();
          break;
        case _AuthMode.signup:
          if (_confirmPasswordController.text.trim() != password) {
            errorMessage = '两次输入的密码不一致';
            break;
          }
          errorMessage = await _signupUser(username, password);
          if (errorMessage == null) _navigateAfterAuth();
          break;
        case _AuthMode.recover:
          errorMessage = await _recoverPassword(username);
          if (errorMessage == null && mounted) {
            _showMessage('密码已重置，请使用新密码登录');
            setState(() => _mode = _AuthMode.login);
          }
          break;
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (errorMessage != null && mounted) {
      _showMessage(errorMessage, isError: true);
    }
  }

  void _navigateAfterAuth() {
    NavigationHelper.offAllNamed(
      RoleUtils.canAccessAdminDashboard(_userRole)
          ? Routes.dashboard
          : Routes.userDashboard,
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    final themeData = _buildTheme();
    final scheme = themeData.colorScheme;
    final accent = isError
        ? scheme.error
        : (themeData.extension<AppColors>()?.success ?? scheme.primary);
    Get.snackbar(
      isError ? '操作失败' : '操作成功',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Color.lerp(scheme.surface, accent, 0.16),
      colorText: scheme.onSurface,
      margin: const EdgeInsets.all(18),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }

  ThemeData _buildTheme() {
    final baseTheme = _theme.isDark ? AppTheme.basicDark : AppTheme.basicLight;
    final scheme = baseTheme.colorScheme;
    final isDark = baseTheme.brightness == Brightness.dark;
    return baseTheme.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.42)
            : scheme.surface.withValues(alpha: 0.92),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 1.7),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.error, width: 1.7),
        ),
      ),
    );
  }

  void _setMode(_AuthMode mode) {
    if (_mode == mode || _isSubmitting) return;
    setState(() {
      _mode = mode;
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = _buildTheme();

    return Theme(
      data: themeData,
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: _StaticLoginBackground()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 920;
                  final verticalInset = wide ? 72.0 : 48.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 56 : 22,
                      vertical: wide ? 36 : 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight -
                            verticalInset.clamp(0, constraints.maxHeight),
                      ),
                      child: wide
                          ? Row(
                              children: [
                                Expanded(child: _brandPane(themeData)),
                                const SizedBox(width: 48),
                                SizedBox(
                                  width: 440,
                                  child: _authPanel(themeData),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _brandPane(themeData, compact: true),
                                const SizedBox(height: 28),
                                _authPanel(themeData),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 22,
              right: 22,
              child: Obx(() {
                final dark = _theme.isDark;
                return Tooltip(
                  message: dark ? '切换到浅色模式' : '切换到深色模式',
                  child: IconButton.filledTonal(
                    onPressed: _theme.toggle,
                    icon: Icon(
                      dark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandPane(ThemeData themeData, {bool compact = false}) {
    final colorScheme = themeData.colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        top: compact ? 18 : 34,
        bottom: compact ? 0 : 34,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            compact ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/images/raster/logo-5.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Final Assignment',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: compact ? 18 : 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 22 : 44),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              '交通违法行为处理管理系统',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: compact ? 30 : 48,
                height: 1.12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              '统一身份认证入口，登录后按角色进入对应工作台。',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: compact ? 15 : 17,
                height: 1.55,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 38),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InfoChip(
                  icon: Icons.verified_user_outlined,
                  label: '统一认证',
                  colorScheme: colorScheme,
                ),
                _InfoChip(
                  icon: Icons.route_outlined,
                  label: '角色分流',
                  colorScheme: colorScheme,
                ),
                _InfoChip(
                  icon: Icons.receipt_long_outlined,
                  label: '业务协同',
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _authPanel(ThemeData themeData) {
    final colorScheme = themeData.colorScheme;
    final isSignup = _mode == _AuthMode.signup;
    final isRecover = _mode == _AuthMode.recover;

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            colorScheme.surface.withValues(alpha: _theme.isDark ? 0.92 : 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _theme.isDark ? 0.28 : 0.08),
            blurRadius: 34,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                switch (_mode) {
                  _AuthMode.login => '登录',
                  _AuthMode.signup => '创建账号',
                  _AuthMode.recover => '重置密码',
                },
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                switch (_mode) {
                  _AuthMode.login => '请输入账号密码继续。',
                  _AuthMode.signup => '注册普通用户账号后将自动登录。',
                  _AuthMode.recover => '验证后设置新的登录密码。',
                },
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.5,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 22),
              SegmentedButton<_AuthMode>(
                segments: const [
                  ButtonSegment(
                    value: _AuthMode.login,
                    icon: Icon(Icons.login_rounded),
                    label: Text('登录'),
                  ),
                  ButtonSegment(
                    value: _AuthMode.signup,
                    icon: Icon(Icons.person_add_alt_1_rounded),
                    label: Text('注册'),
                  ),
                ],
                selected: {
                  _mode == _AuthMode.recover ? _AuthMode.login : _mode
                },
                onSelectionChanged: (selection) => _setMode(selection.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _emailController,
                enabled: !_isSubmitting,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction:
                    isRecover ? TextInputAction.done : TextInputAction.next,
                validator: validateEmail,
                decoration: const InputDecoration(
                  labelText: '用户邮箱',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              if (!isRecover) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isSubmitting,
                  obscureText: _obscurePassword,
                  autofillHints: isSignup
                      ? const [AutofillHints.newPassword]
                      : const [AutofillHints.password],
                  textInputAction:
                      isSignup ? TextInputAction.next : TextInputAction.done,
                  validator: validatePassword,
                  onFieldSubmitted: (_) {
                    if (!isSignup) _submit();
                  },
                  decoration: InputDecoration(
                    labelText: '密码',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                    ),
                  ),
                ),
              ],
              if (isSignup) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: !_isSubmitting,
                  obscureText: _obscureConfirmPassword,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.isEmpty) return '请再次输入密码';
                    if (value != _passwordController.text) {
                      return '两次输入的密码不一致';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: '确认密码',
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirmPassword ? '显示密码' : '隐藏密码',
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Icon(
                        switch (_mode) {
                          _AuthMode.login => Icons.login_rounded,
                          _AuthMode.signup => Icons.person_add_alt_1_rounded,
                          _AuthMode.recover => Icons.lock_reset_rounded,
                        },
                      ),
                label: Text(
                  switch (_mode) {
                    _AuthMode.login => '登录',
                    _AuthMode.signup => '注册并登录',
                    _AuthMode.recover => '重置密码',
                  },
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (!isRecover)
                    TextButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _setMode(_AuthMode.recover),
                      icon: const Icon(Icons.help_outline_rounded),
                      label: const Text('忘记密码'),
                    ),
                  const Spacer(),
                  if (isRecover)
                    TextButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _setMode(_AuthMode.login),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('返回登录'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticLoginBackground extends StatelessWidget {
  const _StaticLoginBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0B1117) : const Color(0xFFF4F7FA),
      ),
      child: CustomPaint(
        painter: _LoginBackgroundPainter(
          primary: scheme.primary,
          outline: scheme.outlineVariant,
          dark: dark,
        ),
      ),
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  const _LoginBackgroundPainter({
    required this.primary,
    required this.outline,
    required this.dark,
  });

  final Color primary;
  final Color outline;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final baseLine = Paint()
      ..color = outline.withValues(alpha: dark ? 0.13 : 0.22)
      ..strokeWidth = 1.0;
    final accentLine = Paint()
      ..color = primary.withValues(alpha: dark ? 0.26 : 0.18)
      ..strokeWidth = 1.4;

    for (double y = 90; y < size.height + 220; y += 96) {
      canvas.drawLine(
        Offset(-80, y),
        Offset(size.width + 80, y - 180),
        baseLine,
      );
    }

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.78)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.62,
        size.width * 0.48,
        size.height * 0.84,
        size.width * 0.74,
        size.height * 0.68,
      )
      ..cubicTo(
        size.width * 0.86,
        size.height * 0.60,
        size.width * 0.94,
        size.height * 0.58,
        size.width * 1.04,
        size.height * 0.52,
      );
    canvas.drawPath(path, accentLine);
  }

  @override
  bool shouldRepaint(covariant _LoginBackgroundPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.outline != outline ||
        oldDelegate.dark != dark;
  }
}
