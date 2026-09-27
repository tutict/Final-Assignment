import 'package:final_assignment_front/features/api/offense_type_controller_api.dart';
import 'package:final_assignment_front/features/api/payment_record_controller_api.dart';
import 'package:final_assignment_front/features/api/permission_management_controller_api.dart';
import 'package:final_assignment_front/features/api/role_management_controller_api.dart';
import 'package:final_assignment_front/features/api/system_logs_controller_api.dart';
import 'package:final_assignment_front/features/api/system_settings_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/system/simple_records_page.dart';
import 'package:flutter/material.dart';

class RoleRecordsPage extends StatelessWidget {
  const RoleRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleRecordsPage(
      title: '角色',
      subtitle: '查看已有角色，不新增接口。',
      columns: const ['角色名称', '角色编码', '类型', '状态'],
      load: () async {
        final api = RoleManagementControllerApi();
        await api.initializeWithJwt();
        final rows = await api.listRoles();
        return [
          for (final row in rows)
            {
              '角色名称': row.roleName ?? '',
              '角色编码': row.roleCode ?? '',
              '类型': row.roleType ?? '',
              '状态': row.status ?? '',
            },
        ];
      },
    );
  }
}

class PermissionRecordsPage extends StatelessWidget {
  const PermissionRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleRecordsPage(
      title: '权限',
      subtitle: '查看权限名称和菜单路径。',
      columns: const ['权限名称', '权限编码', '类型', '菜单'],
      load: () async {
        final api = PermissionManagementControllerApi();
        await api.initializeWithJwt();
        final rows = await api.listPermissions();
        return [
          for (final row in rows)
            {
              '权限名称': row.permissionName ?? '',
              '权限编码': row.permissionCode ?? '',
              '类型': row.permissionType ?? '',
              '菜单': row.menuPath ?? '',
            },
        ];
      },
    );
  }
}

class OffenseTypeRecordsPage extends StatelessWidget {
  const OffenseTypeRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleRecordsPage(
      title: '违法类型',
      subtitle: '查看违法类型字典。',
      columns: const ['名称', '编码', '分类', '状态'],
      load: () async {
        final api = OffenseTypeControllerApi();
        await api.initializeWithJwt();
        final rows = await api.listOffenseTypes();
        return [
          for (final row in rows)
            {
              '名称': row.offenseName ?? '',
              '编码': row.offenseCode ?? '',
              '分类': row.category ?? '',
              '状态': row.status ?? '',
            },
        ];
      },
    );
  }
}

class PaymentRecordsPage extends StatelessWidget {
  const PaymentRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleRecordsPage(
      title: '缴费流水',
      subtitle: '查看缴费记录。',
      columns: const ['缴费人', '缴费单号', '金额', '状态'],
      load: () async {
        final api = PaymentRecordControllerApi();
        await api.initializeWithJwt();
        final rows = await api.listPayments();
        return [
          for (final row in rows)
            {
              '缴费人': row.payerName ?? '',
              '缴费单号': row.paymentNumber ?? '',
              '金额': row.paymentAmount?.toString() ?? '',
              '状态': row.paymentStatus ?? '',
            },
        ];
      },
    );
  }
}

class SystemSettingsRecordsPage extends StatelessWidget {
  const SystemSettingsRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleRecordsPage(
      title: '系统参数',
      subtitle: '查看系统参数，不展示邮箱密码。',
      columns: const ['系统名称', '参数键', '参数值', '分类'],
      load: () async {
        final api = SystemSettingsControllerApi();
        await api.initializeWithJwt();
        final rows = await api.listSystemSettings();
        return [
          for (final row in rows)
            {
              '系统名称': row.systemName ?? '',
              '参数键': row.settingKey ?? '',
              '参数值': row.isEncrypted == true ? '已加密' : (row.settingValue ?? ''),
              '分类': row.category ?? '',
            },
        ];
      },
    );
  }
}

class RequestHistoryPage extends StatefulWidget {
  const RequestHistoryPage({super.key});

  @override
  State<RequestHistoryPage> createState() => _RequestHistoryPageState();
}

class _RequestHistoryPageState extends State<RequestHistoryPage> {
  final _value = TextEditingController();
  String _field = 'method';
  String? _error;
  bool _loading = false;
  List<Map<String, String>> _rows = const [];

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _value.text.trim();
    if (query.isEmpty) {
      setState(() => _error = '请输入搜索条件后再查询。');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = SystemLogsControllerApi();
      await api.initializeWithJwt();
      final result = switch (_field) {
        'url' => await api.searchRequestHistoryByUrl(requestUrl: query),
        'status' => await api.searchRequestHistoryByStatus(status: query),
        'ip' => await api.searchRequestHistoryByIp(requestIp: query),
        'idempotency' => await api.searchRequestHistoryByIdempotency(key: query),
        _ => await api.searchRequestHistoryByMethod(requestMethod: query),
      };
      setState(() {
        _rows = [
          for (final row in result)
            {
              'URL': row.requestUrl ?? '',
              '方法': row.requestMethod ?? '',
              '状态': row.businessStatus ?? '',
              'IP': row.requestIp ?? '',
            },
        ];
      });
    } catch (_) {
      setState(() => _error = '没有查到请求记录。请修改条件后重试。');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('请求记录', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<String>(
                value: _field,
                items: const [
                  DropdownMenuItem(value: 'method', child: Text('方法')),
                  DropdownMenuItem(value: 'url', child: Text('URL')),
                  DropdownMenuItem(value: 'status', child: Text('状态')),
                  DropdownMenuItem(value: 'ip', child: Text('IP')),
                  DropdownMenuItem(value: 'idempotency', child: Text('幂等键')),
                ],
                onChanged: (value) => setState(() => _field = value ?? 'method'),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _value,
                  decoration: const InputDecoration(labelText: '搜索条件'),
                ),
              ),
              FilledButton(onPressed: _loading ? null : _search, child: const Text('查询')),
            ],
          ),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!)),
          const SizedBox(height: 12),
          if (_loading) const Text('正在查询，请稍候。'),
          if (!_loading && _rows.isEmpty) const Text('还没有结果。输入条件后查询。'),
          Expanded(
            child: ListView(
              children: [
                for (final row in _rows)
                  ListTile(
                    title: Text(row['URL']!.isEmpty ? row['方法']! : row['URL']!),
                    subtitle: Text('${row['方法']} · ${row['状态']} · ${row['IP']}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
