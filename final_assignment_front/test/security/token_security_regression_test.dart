import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current;
  final libDir = Directory('${root.path}/lib');

  List<File> dartFiles() => libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  test('auth tokens are not written to SharedPreferences directly', () {
    final violations = <String>[];
    final tokenKeyPattern = RegExp(
      r'''\.(setString|getString|remove)\(\s*['"](?:jwt_token|jwtToken|refresh_token|refreshToken)['"]''',
    );

    for (final file in dartFiles()) {
      final relativePath = file.path.replaceFirst(
        '${root.path}${Platform.pathSeparator}',
        '',
      );
      if (relativePath.endsWith(
        'lib${Platform.pathSeparator}utils${Platform.pathSeparator}services${Platform.pathSeparator}auth_token_store.dart',
      )) {
        continue;
      }
      final source = file.readAsStringSync();
      if (tokenKeyPattern.hasMatch(source)) {
        violations.add(relativePath);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use AuthTokenStore so JWT/refresh tokens stay in secure storage on native platforms.',
    );
  });

  test('AuthTokenStore keeps native tokens in secure storage and persists web tokens under dedicated keys', () {
    final source = File(
      '${root.path}/lib/utils/services/auth_token_store.dart',
    ).readAsStringSync();

    expect(source, contains('FlutterSecureStorage'));
    expect(source, contains('if (kIsWeb)'));

    // 原生端令牌只落 secure storage，legacy 键不得经 SharedPreferences 写入。
    for (final key in ['jwt_token', 'jwtToken', 'refresh_token', 'refreshToken']) {
      expect(source, isNot(contains("setString('$key'")));
      expect(source, isNot(contains('setString("$key"')));
    }
    expect(source, contains('_secureStorage.write(key: secureKey, value: normalized)'));

    // Web 端没有 secure storage，刷新不掉登录要求令牌落在 localStorage 的专用键上。
    expect(source, contains("'auth_web_jwt_token'"));
    expect(source, contains("'auth_web_refresh_token'"));
    expect(source, contains('prefs.setString(webKey, value)'));
  });

  test('websocket URLs never carry bearer access tokens', () {
    final apiClient = File(
      '${root.path}/lib/core/network/api_client.dart',
    ).readAsStringSync();

    expect(apiClient, isNot(contains("'access_token'")));
    expect(apiClient, isNot(contains('"access_token"')));
    expect(apiClient, isNot(contains('accessToken=')));
    expect(apiClient, contains("'ws_ticket'"));
    expect(apiClient, contains(r"headers['Authorization'] = 'Bearer $token'"));
  });

  test('debug logs do not print raw JWT values or decoded token maps', () {
    final violations = <String>[];
    final unsafeLogPattern = RegExp(
      r'''AppLogger\.(?:debug|info|warning|error)\([^\n]*(?:\$jwtToken|Decoded JWT|New JWT decoded|Retrieved JWT)''',
    );

    for (final file in dartFiles()) {
      final relativePath = file.path.replaceFirst(
        '${root.path}${Platform.pathSeparator}',
        '',
      );
      final source = file.readAsStringSync();
      if (unsafeLogPattern.hasMatch(source)) {
        violations.add(relativePath);
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'JWTs and decoded claim maps must not be written to app logs.',
    );
  });

  test('production config must not fall back to placeholder hosts', () {
    final source =
        File('${root.path}/lib/core/config/app_config.dart').readAsStringSync();

    expect(
      source,
      contains(
          'Production builds must define PROD_API_BASE_URL or API_BASE_URL.'),
    );
    expect(source, contains("configuredBaseUrl.contains('api.example.com')"));
    expect(source, contains("'10.0.2.2'"));
    expect(source, isNot(contains("defaultValue: 'https://api.example.com'")));
  });
}
