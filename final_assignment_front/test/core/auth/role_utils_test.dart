import 'dart:io';

import 'package:final_assignment_front/core/auth/role_utils.dart';
import 'package:flutter_test/flutter_test.dart';

/// 管理端业务页面的准入规则：SUPER_ADMIN 是 ADMIN 的超集。
///
/// 后端对罚款、扣分、违法、车辆等管理接口一律放行 SUPER_ADMIN，管理端页面也把
/// 同一批入口展示给超管；页面若按角色名精确相等判定，超管会看到"权限不足"。
void main() {
  group('RoleUtils.canManageBusiness', () {
    test('放行 ADMIN 与 SUPER_ADMIN', () {
      expect(RoleUtils.canManageBusiness(['ADMIN']), isTrue);
      expect(RoleUtils.canManageBusiness(['SUPER_ADMIN']), isTrue);
      expect(RoleUtils.canManageBusiness('SUPER_ADMIN'), isTrue);
      expect(RoleUtils.canManageBusiness('ADMIN'), isTrue);
    });

    test('拒绝非管理角色', () {
      expect(RoleUtils.canManageBusiness(['USER']), isFalse);
      expect(RoleUtils.canManageBusiness(['TRAFFIC_POLICE']), isFalse);
      expect(RoleUtils.canManageBusiness(['APPEAL_REVIEWER']), isFalse);
      expect(RoleUtils.canManageBusiness(null), isFalse);
      expect(RoleUtils.canManageBusiness(''), isFalse);
    });

    test('多角色时只要含管理角色即放行', () {
      expect(RoleUtils.canManageBusiness(['APPEAL_REVIEWER', 'SUPER_ADMIN']), isTrue);
    });
  });

  test('代码库不再用角色名精确相等做管理端准入判定', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (source.contains("contains('ADMIN')") ||
          source.contains('contains("ADMIN")')) {
        offenders.add(entity.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          '管理端页面必须用 requireManagerRoles()/RoleUtils.canManageBusiness 判定准入，'
          '否则 SUPER_ADMIN 会被误判为"权限不足"。',
    );
  });
}
