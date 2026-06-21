import 'package:flutter/foundation.dart';

enum AppEnv { dev, prod }

class AppConfig {
  const AppConfig._();

  static const envName = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  static const apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static const wsBaseUrlOverride =
      String.fromEnvironment('WS_BASE_URL', defaultValue: '');

  static const devBackendHost =
      String.fromEnvironment('DEV_BACKEND_HOST', defaultValue: '');

  static const aiBasePath =
      String.fromEnvironment('AI_BASE_PATH', defaultValue: '/api/ai');

  static const apiPort = int.fromEnvironment('API_PORT', defaultValue: 8080);

  static const wsPort = int.fromEnvironment('WS_PORT', defaultValue: 8081);

  static const apiPortOffset =
      int.fromEnvironment('API_PORT_OFFSET', defaultValue: 0);

  static const prodApiBaseUrl = String.fromEnvironment(
    'PROD_API_BASE_URL',
    defaultValue: '',
  );

  static bool get isWeb => kIsWeb;

  static AppEnv get env =>
      envName.toLowerCase() == 'prod' ? AppEnv.prod : AppEnv.dev;

  static bool get isProd => env == AppEnv.prod;

  static String get apiBaseUrl {
    if (isProd) {
      return _requiredProdBaseUrl();
    }

    if (apiBaseUrlOverride.isNotEmpty) {
      return _withoutTrailingSlash(apiBaseUrlOverride);
    }

    const port = apiPort + apiPortOffset;
    return '$_devApiScheme://$_devHost:$port';
  }

  static String get wsBaseUrl {
    if (wsBaseUrlOverride.isNotEmpty) {
      return _withoutTrailingSlash(wsBaseUrlOverride);
    }

    if (isProd) {
      return _toWsBaseUrl(_requiredProdBaseUrl());
    }

    return '$_devWsScheme://$_devHost:$wsPort';
  }

  static String get _devHost {
    if (devBackendHost.isNotEmpty) {
      return devBackendHost;
    }

    if (kIsWeb) {
      return Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
    }

    return defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
  }

  static String get _devApiScheme {
    if (!kIsWeb) return 'http';
    return Uri.base.scheme.startsWith('http') ? Uri.base.scheme : 'http';
  }

  static String get _devWsScheme {
    if (!kIsWeb) return 'ws';
    return Uri.base.scheme == 'https' ? 'wss' : 'ws';
  }

  static String _requiredProdBaseUrl() {
    final configuredBaseUrl =
        apiBaseUrlOverride.isNotEmpty ? apiBaseUrlOverride : prodApiBaseUrl;
    if (configuredBaseUrl.isEmpty ||
        configuredBaseUrl.contains('api.example.com')) {
      throw StateError(
        'Production builds must define PROD_API_BASE_URL or API_BASE_URL.',
      );
    }
    return _withoutTrailingSlash(configuredBaseUrl);
  }

  static String _toWsBaseUrl(String httpBaseUrl) {
    if (httpBaseUrl.startsWith('https://')) {
      return httpBaseUrl.replaceFirst('https://', 'wss://');
    }
    if (httpBaseUrl.startsWith('http://')) {
      return httpBaseUrl.replaceFirst('http://', 'ws://');
    }
    throw StateError(
      'Production API base URL must start with http:// or https://.',
    );
  }

  static String _withoutTrailingSlash(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }
}
