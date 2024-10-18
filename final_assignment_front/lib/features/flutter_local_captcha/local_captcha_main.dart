import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_captcha/local_captcha.dart';

class LocalCaptchaMain extends StatefulWidget {
  const LocalCaptchaMain({super.key});

  @override
  LocalCaptchaMainState createState() => LocalCaptchaMainState();
}

class LocalCaptchaMainState extends State<LocalCaptchaMain> {
  static final _captchaFormKey = GlobalKey<FormState>();
  static final _localCaptchaController = LocalCaptchaController();
  static final _configFormData = ConfigFormData();
  static final _refreshButtonEnableVN = ValueNotifier(true);

  String _inputCode = '';
  Timer? _refreshTimer;

  @override
  void dispose() {
    _localCaptchaController.dispose();
    _refreshTimer?.cancel();
    _refreshTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('验证码'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SizedBox(
            width: 300.0,
            child: Form(
              key: _captchaFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LocalCaptcha(
                    key: ValueKey(_configFormData.toString()),
                    controller: _localCaptchaController,
                    height: 150,
                    width: 300,
                    backgroundColor: Colors.grey[100]!,
                    chars: _configFormData.chars,
                    length: _configFormData.length,
                    fontSize: _configFormData.fontSize > 0
                        ? _configFormData.fontSize
                        : null,
                    caseSensitive: _configFormData.caseSensitive,
                    codeExpireAfter: _configFormData.codeExpireAfter,
                    onCaptchaGenerated: (captcha) {
                      debugPrint('生成验证码: $captcha');
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '输入验证码',
                      hintText: '输入验证码',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (value.length != _configFormData.length) {
                          return '* Code must be length of ${_configFormData.length}.';
                        }

                        final validation =
                        _localCaptchaController.validate(value);

                        switch (validation) {
                          case LocalCaptchaValidation.invalidCode:
                            return '* Invalid code.';
                          case LocalCaptchaValidation.codeExpired:
                            return '* Code expired.';
                          case LocalCaptchaValidation.valid:
                            return null;
                        }
                      }
                      return '* Required field.';
                    },
                    onSaved: (value) => _inputCode = value ?? '',
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    height: 40.0,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_captchaFormKey.currentState?.validate() ?? false) {
                          _captchaFormKey.currentState!.save();

                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Code: "$_inputCode" is valid.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                      child: const Text('Validate Code'),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    height: 40.0,
                    width: double.infinity,
                    child: ValueListenableBuilder(
                        valueListenable: _refreshButtonEnableVN,
                        builder: (context, enable, child) {
                          final onPressed = enable
                              ? () {
                            if (_refreshTimer == null) {
                              // Prevent spam pressing refresh button.
                              _refreshTimer =
                                  Timer(const Duration(seconds: 1), () {
                                    _refreshButtonEnableVN.value = true;
                                    _refreshTimer?.cancel();
                                    _refreshTimer = null;
                                  });

                              _refreshButtonEnableVN.value = false;
                              _localCaptchaController.refresh();
                            }
                          }
                              : null;

                          return ElevatedButton(
                            onPressed: onPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                            ),
                            child: const Text('Refresh'),
                          );
                        }),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ConfigFormData {
  String chars =
      'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890';
  int length = 5;
  double fontSize = 0;
  bool caseSensitive = false;
  Duration codeExpireAfter = const Duration(minutes: 10);

  @override
  String toString() {
    return '$chars$length$caseSensitive${codeExpireAfter.inMinutes}';
  }
}
