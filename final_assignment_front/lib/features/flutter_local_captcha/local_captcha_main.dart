import 'dart:async';

import 'package:flutter/material.dart';
import 'package:local_captcha/local_captcha.dart';

class LocalCaptchaMain extends StatefulWidget {

  static final _captchaFormKey = GlobalKey<FormState>();
  static final _configFormKey = GlobalKey<FormState>();
  static final _localCaptchaController = LocalCaptchaController();
  static final _configFormData = ConfigFormData();
  static final _refreshButtonEnableVN = ValueNotifier(true);

  var _inputCode = '';
  Timer? _refreshTimer;

  void dispose() {
    _localCaptchaController.dispose();
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

}

class ConfigFormData {
  String chars = 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890';
  int length = 5;
  double fontSize = 0;
  bool caseSensitive = false;
  Duration codeExpireAfter = const Duration(minutes: 10);

  @override
  String toString() {
    return '$chars$length$caseSensitive${codeExpireAfter.inMinutes}';
  }
}
