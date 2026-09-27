import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/api/fine_information_controller_api.dart';
import 'package:final_assignment_front/features/api/progress_item_controller_api.dart';
import 'package:flutter/material.dart';

class DriverHomeCounts extends StatefulWidget {
  const DriverHomeCounts({super.key, required this.onOpen});

  final void Function(String route) onOpen;

  @override
  State<DriverHomeCounts> createState() => _DriverHomeCountsState();
}

class _DriverHomeCountsState extends State<DriverHomeCounts> {
  bool _loading = true;
  String? _error;
  String _unpaid = '-';
  String _appeals = '-';
  String _messages = '-';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    var failed = false;
    var unpaid = '-';
    var appeals = '-';
    var messages = '-';
    try {
      final api = FineInformationControllerApi();
      await api.initializeWithJwt();
      final fines = await api.listFines();
      unpaid = fines.where((fine) {
        final raw = fine.paymentStatus ?? '';
        final status = raw.toUpperCase();
        return !(status.contains('PAID') ||
            status.contains('SUCCESS') ||
            raw.contains('已缴') ||
            raw.contains('已支付'));
      }).length.toString();
    } catch (_) {
      failed = true;
    }
    try {
      final api = AppealManagementControllerApi();
      await api.initializeWithJwt();
      final rows = await api.listMyAppeals();
      const closed = {'APPROVED', 'REJECTED', 'CLOSED', 'COMPLETED', 'ARCHIVED'};
      appeals = rows.where((row) {
        final status = (row.processStatus ?? row.acceptanceStatus ?? '').toUpperCase();
        return status.isEmpty || !closed.contains(status);
      }).length.toString();
    } catch (_) {
      failed = true;
    }
    try {
      final api = ProgressControllerApi();
      await api.initializeWithJwt();
      final rows = await api.listProgressItems();
      messages = rows.length.toString();
    } catch (_) {
      failed = true;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _unpaid = unpaid;
      _appeals = appeals;
      _messages = messages;
      _error = failed ? '部分首页数字没有加载成功，可以重试。' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _CountCard(label: '待缴费', value: _loading ? '-' : _unpaid, onTap: () => widget.onOpen('/fineInformation')),
            _CountCard(label: '处理中申诉', value: _loading ? '-' : _appeals, onTap: () => widget.onOpen('/userAppeal')),
            _CountCard(label: '未读消息', value: _loading ? '-' : _messages, onTap: () => widget.onOpen('/onlineProcessingProgress')),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: theme.textTheme.bodySmall),
          TextButton(onPressed: _load, child: const Text('重试')),
        ],
      ],
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 180,
      child: OutlinedButton(
        onPressed: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(value, style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
