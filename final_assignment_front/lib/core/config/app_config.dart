import 'package:flutter/foundation.dart';

enum AppEnv { dev, prod }

class AppConfig {
  const AppConfig._();

  static const envName = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  static const apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static const wsBaseUrlOverride =
      String.fromEnvironment('WS_BASE_URL', defaultValue: '');

  static const apiPort = int.fromEnvironment('API_PORT', defaultValue: 8080);

  static const wsPort = int.fromEnvironment('WS_PORT', defaultValue: 8081);

  static const apiPortOffset =
      int.fromEnvironment('API_PORT_OFFSET', defaultValue: 0);

  static const prodApiBaseUrl = String.fromEnvironment(
    'PROD_API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  static bool get isWeb => kIsWeb;

  static AppEnv get env =>
      envName.toLowerCase() == 'prod' ? AppEnv.prod : AppEnv.dev;

  static bool get isProd => env == AppEnv.prod;

  static String get apiBaseUrl {
    if (apiBaseUrlOverride.isNotEmpty) {
      return _withoutTrailingSlash(apiBaseUrlOverride);
    }

    if (isProd) {
      return _withoutTrailingSlash(prodApiBaseUrl);
    }

    final port = apiPort + apiPortOffset;

    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      final scheme =
          Uri.base.scheme.startsWith('http') ? Uri.base.scheme : 'http';
      return '$scheme://$host:$port';
    }

    return 'http://localhost:$port';
  }

  static String get wsBaseUrl {
    if (wsBaseUrlOverride.isNotEmpty) {
      return _withoutTrailingSlash(wsBaseUrlOverride);
    }

    if (isProd) {
      final prodUrl = _withoutTrailingSlash(prodApiBaseUrl);
      return prodUrl.startsWith('https')
          ? prodUrl.replaceFirst('https', 'wss')
          : prodUrl.replaceFirst('http', 'ws');
    }

    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      final scheme = Uri.base.scheme == 'https' ? 'wss' : 'ws';
      return '$scheme://$host:$wsPort';
    }

    return 'ws://localhost:$wsPort';
  }

  static String _withoutTrailingSlash(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }
}
