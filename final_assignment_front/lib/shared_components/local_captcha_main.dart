import 'dart:async';
import 'package:flutter/material.dart';
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

  String _inputCode = '';
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    Future.delayed(const Duration(milliseconds: 100), () {
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
    while (_isMounted) {
      if (_captchaFormKey.currentState?.validate() ?? false) {
        _captchaFormKey.currentState!.save();
        final validation = _localCaptchaController.validate(_inputCode);
        debugPrint('Captcha validation: $validation (input: $_inputCode)');
        if (validation == LocalCaptchaValidation.valid) {
          return true; // 验证成功
        } else {
          // 验证失败，刷新验证码并显示错误提示
          _localCaptchaController.refresh();
          _inputController.clear();
          _inputCode = '';
          if (_isMounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('验证码错误，请重试'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } else {
        // 用户未输入直接点击验证，继续等待
        debugPrint('Form validation failed, empty or invalid input');
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }
    }
    debugPrint('Exited captcha loop due to unmount');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      title: Text(
        '验证码验证',
        style: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[800],
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
                  backgroundColor: Colors.grey[200]!,
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
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    labelStyle: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.blueGrey[600],
                    ),
                    hintStyle: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.black87,
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
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
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
              color: Colors.blueGrey[600],
            ),
          ),
        ),
      ],
    );
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
