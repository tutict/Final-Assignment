// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/dashboard/views/user/user_dashboard.dart';
import 'package:get/get.dart';
import 'package:local_captcha/local_captcha.dart';
import 'package:google_fonts/google_fonts.dart';

class LocalCaptchaMain extends StatefulWidget {
  const LocalCaptchaMain({super.key});

  @override
  State<LocalCaptchaMain> createState() => _LocalCaptchaMainState();
}

class _LocalCaptchaMainState extends State<LocalCaptchaMain> {
  final _captchaFormKey = GlobalKey<FormState>();
  final _localCaptchaController = LocalCaptchaController();
  final _configFormData = ConfigFormData();
  final _inputController = TextEditingController();
  final UserDashboardController _controller =
      Get.find<UserDashboardController>();

  String _inputCode = '';
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    // Delay refresh until widget is fully painted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMounted) {
        _localCaptchaController.refresh();
        debugPrint('Captcha refreshed on init');
      }
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    _inputController.dispose();
    _localCaptchaController.dispose();
    super.dispose();
  }

  Future<bool> _validateCaptcha() async {
    if (!_isMounted) return false;

    if (_captchaFormKey.currentState?.validate() ?? false) {
      _captchaFormKey.currentState!.save();
      final validation = _localCaptchaController.validate(_inputCode);
      debugPrint('Captcha validation: $validation (input: $_inputCode)');
      if (validation == LocalCaptchaValidation.valid) {
        return true; // Validation successful
      } else {
        // Validation failed, refresh captcha and show error
        _localCaptchaController.refresh();
        _inputController.clear();
        _inputCode = '';
        if (_isMounted) {
          final themeData = _controller.currentBodyTheme.value;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('验证码错误，请重试',
                  style:
                      TextStyle(color: themeData.colorScheme.onErrorContainer)),
              backgroundColor: themeData.colorScheme.error,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return false;
      }
    } else {
      debugPrint('Form validation failed, empty or invalid input');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Reactive theme updates
      final isLight = _controller.currentTheme.value == 'Light';
      final themeData = _controller.currentBodyTheme.value;

      return Theme(
        data: themeData,
        child: AlertDialog(
          backgroundColor: isLight
              ? themeData.colorScheme.surfaceContainer
              : themeData.colorScheme.surfaceContainerHigh,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Text(
            '验证码验证',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isLight
                  ? themeData.colorScheme.onSurface
                  : themeData.colorScheme.onSurface.withValues(alpha: 0.95),
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400.0,
              child: Form(
                key: _captchaFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LocalCaptcha(
                      key: ValueKey(_configFormData.toString()),
                      controller: _localCaptchaController,
                      height: 240,
                      width: 400,
                      backgroundColor: isLight
                          ? themeData.colorScheme.surfaceContainerLowest
                          : themeData.colorScheme.surfaceContainerLow,
                      chars: _configFormData.chars,
                      length: _configFormData.length,
                      fontSize: _configFormData.fontSize,
                      caseSensitive: _configFormData.caseSensitive,
                      codeExpireAfter: _configFormData.codeExpireAfter,
                      onCaptchaGenerated: (captcha) {
                        debugPrint('生成验证码: $captcha');
                        debugPrint('应用字体大小: ${_configFormData.fontSize}');
                      },
                    ),
                    const SizedBox(height: 20.0),
                    TextFormField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        labelText: '输入验证码',
                        hintText: '请输入验证码',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(
                              color: themeData.colorScheme.outline
                                  .withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(
                              color: themeData.colorScheme.primary, width: 2.0),
                        ),
                        filled: true,
                        fillColor: isLight
                            ? themeData.colorScheme.surfaceContainerLowest
                            : themeData.colorScheme.surfaceContainerLow,
                        labelStyle: GoogleFonts.roboto(
                          fontSize: 16,
                          color: isLight
                              ? themeData.colorScheme.onSurfaceVariant
                              : themeData.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.85),
                        ),
                        hintStyle: GoogleFonts.roboto(
                          fontSize: 16,
                          color: isLight
                              ? themeData.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6)
                              : themeData.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                        ),
                      ),
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: isLight
                            ? themeData.colorScheme.onSurface
                            : themeData.colorScheme.onSurface.withValues(alpha: 0.95),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '* 请输入验证码';
                        }
                        if (value.length != _configFormData.length) {
                          return '* 验证码长度应为 ${_configFormData.length}';
                        }
                        return null;
                      },
                      onSaved: (value) => _inputCode = value ?? '',
                    ),
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                      onPressed: () async {
                        final isValid = await _validateCaptcha();
                        if (_isMounted) {
                          Navigator.of(context).pop(isValid);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeData.colorScheme.primary,
                        foregroundColor: themeData.colorScheme.onPrimary,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        '验证',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeData.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_isMounted) {
                  Navigator.of(context).pop(false);
                }
              },
              child: Text(
                '取消',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: isLight
                      ? themeData.colorScheme.onSurfaceVariant
                      : themeData.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class ConfigFormData {
  String chars =
      'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890';
  int length = 4;
  double fontSize = 84;
  bool caseSensitive = false;
  Duration codeExpireAfter = const Duration(minutes: 10);

  @override
  String toString() {
    return '$chars$length$caseSensitive${codeExpireAfter.inMinutes}';
  }
}
