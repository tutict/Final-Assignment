// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:final_assignment_front/features/dashboard/bindings/progress_binding.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/controllers/progress_controller.dart';
import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ProgressDetailPage extends StatefulWidget {
  const ProgressDetailPage({super.key, required this.item});

  final ProgressItem item;

  @override
  State<ProgressDetailPage> createState() => _ProgressDetailPageState();
}

class _ProgressDetailPageState extends State<ProgressDetailPage> {
  late ProgressItem _item;
  late final ProgressController _progressController;

  final UserDashboardController? _userDashboardController =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;
  final ManagerDashboardController? _managerDashboardController =
      Get.isRegistered<ManagerDashboardController>()
          ? Get.find<ManagerDashboardController>()
          : null;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    ProgressBinding.registerDependencies();
    _progressController = Get.find<ProgressController>();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = _resolveThemeData(context);
      final scheme = themeData.colorScheme;

      return Theme(
        data: themeData,
        child: Scaffold(
          backgroundColor: scheme.surface,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final compact = width < 760;
                final horizontalPadding = width < 520 ? 14.0 : 24.0;

                return Column(
                  children: [
                    _DetailTopBar(
                      title: '进度详情',
                      status: _item.status,
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          18,
                          horizontalPadding,
                          24,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1180),
                            child: compact
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: _buildPageSections(themeData),
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 7,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children:
                                              _buildPrimarySections(themeData),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 4,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children:
                                              _buildAsideSections(themeData),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildPageSections(ThemeData themeData) {
    return [
      _buildSummaryPanel(themeData),
      const SizedBox(height: 14),
      _buildTimelinePanel(themeData),
      const SizedBox(height: 14),
      _buildBusinessPanel(themeData),
      const SizedBox(height: 14),
      _buildDetailsPanel(themeData),
      if (_progressController.isAdmin) ...[
        const SizedBox(height: 14),
        _buildAdminActionPanel(themeData),
      ],
    ];
  }

  List<Widget> _buildPrimarySections(ThemeData themeData) {
    return [
      _buildSummaryPanel(themeData),
      const SizedBox(height: 14),
      _buildDetailsPanel(themeData),
    ];
  }

  List<Widget> _buildAsideSections(ThemeData themeData) {
    return [
      _buildTimelinePanel(themeData),
      const SizedBox(height: 14),
      _buildBusinessPanel(themeData),
      if (_progressController.isAdmin) ...[
        const SizedBox(height: 14),
        _buildAdminActionPanel(themeData),
      ],
    ];
  }

  Widget _buildSummaryPanel(ThemeData themeData) {
    final scheme = themeData.colorScheme;
    final statusColor = _statusColor(_item.status, themeData);
    final title = _item.title.trim().isEmpty ? '未命名进度' : _item.title.trim();

    return _DetailPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusToken(status: _item.status),
              _InfoChip(
                icon: Icons.tag_rounded,
                label: '进度编号',
                value: _item.id == null ? '未生成' : '#${_item.id}',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: themeData.textTheme.headlineSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _businessContext(_item),
            style: themeData.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 560;
              final facts = [
                _DetailFact(
                  icon: Icons.person_outline_rounded,
                  label: '提交用户',
                  value: _emptyFallback(_item.username, '未记录'),
                ),
                _DetailFact(
                  icon: Icons.schedule_rounded,
                  label: '提交时间',
                  value: _formatDateTime(_item.submitTime),
                ),
                _DetailFact(
                  icon: Icons.flag_outlined,
                  label: '当前状态',
                  value: _statusLabel(_item.status),
                  color: statusColor,
                ),
                _DetailFact(
                  icon: Icons.link_rounded,
                  label: '关联数量',
                  value: '${_businessLinks(_item).length} 项',
                ),
              ];

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: facts
                    .map(
                      (fact) => SizedBox(
                        width: twoColumns
                            ? (constraints.maxWidth - 10) / 2
                            : constraints.maxWidth,
                        child: _FactTile(fact: fact),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelinePanel(ThemeData themeData) {
    final steps = _timelineSteps(_item.status);

    return _DetailPanel(
      title: '办理时间线',
      subtitle: '按当前状态生成的办理节点',
      child: Column(
        children: [
          for (var index = 0; index < steps.length; index++)
            _TimelineRow(
              step: steps[index],
              isLast: index == steps.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildBusinessPanel(ThemeData themeData) {
    final links = _businessLinks(_item);
    final scheme = themeData.colorScheme;

    return _DetailPanel(
      title: '关联业务',
      subtitle: links.isEmpty ? '暂无关联业务编号' : '由后端进度记录中的关联字段生成',
      child: links.isEmpty
          ? const _InlineEmpty(
              icon: Icons.link_off_rounded,
              message: '这条进度暂未绑定申诉、罚款、车辆或违法记录。',
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: links
                  .map(
                    (link) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(link.icon, size: 17, color: scheme.primary),
                          const SizedBox(width: 7),
                          Text(
                            '${link.label} #${link.id}',
                            style: themeData.textTheme.labelMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildDetailsPanel(ThemeData themeData) {
    final scheme = themeData.colorScheme;
    final detailText = _formatDetails(_item.details);

    return _DetailPanel(
      title: '详情内容',
      subtitle: '来自进度记录的业务说明或请求参数',
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(
            alpha: themeData.brightness == Brightness.dark ? 0.34 : 0.58,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.38),
          ),
        ),
        child: SelectableText(
          detailText,
          style: themeData.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface,
            height: 1.56,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildAdminActionPanel(ThemeData themeData) {
    final canOperate = _item.id != null;

    return _DetailPanel(
      title: '管理员操作',
      subtitle: canOperate ? '更新办理状态或删除当前进度' : '缺少进度编号，暂不可操作',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusActionButton(
                label: '设为处理中',
                icon: Icons.sync_rounded,
                status: 'Processing',
                currentStatus: _item.status,
                enabled: canOperate,
                onPressed: () => _updateStatus('Processing', themeData),
              ),
              _StatusActionButton(
                label: '设为已完成',
                icon: Icons.check_circle_outline_rounded,
                status: 'Completed',
                currentStatus: _item.status,
                enabled: canOperate,
                onPressed: () => _updateStatus('Completed', themeData),
              ),
              _StatusActionButton(
                label: '设为已归档',
                icon: Icons.inventory_2_outlined,
                status: 'Archived',
                currentStatus: _item.status,
                enabled: canOperate,
                onPressed: () => _updateStatus('Archived', themeData),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: canOperate ? () => _confirmDelete(themeData) : null,
            icon: const Icon(Icons.delete_outline_rounded, size: 19),
            label: const Text('删除进度记录'),
            style: OutlinedButton.styleFrom(
              foregroundColor: themeData.colorScheme.error,
              side: BorderSide(
                color: themeData.colorScheme.error.withValues(alpha: 0.38),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ThemeData _resolveThemeData(BuildContext context) {
    if (_userDashboardController != null) {
      return _userDashboardController.currentBodyTheme.value;
    }
    if (_managerDashboardController != null) {
      return _managerDashboardController.currentBodyTheme.value;
    }
    return Theme.of(context);
  }

  Future<void> _updateStatus(String status, ThemeData themeData) async {
    if (_item.id == null) {
      _showSnackBar('无法更新：进度编号为空', isError: true);
      return;
    }
    if (_item.status == status) return;

    try {
      await _progressController.updateProgressStatus(_item.id!, status);
      if (!mounted) return;
      setState(() {
        _item = _item.copyWith(status: status, submitTime: DateTime.now());
      });
      _showSnackBar('进度状态已更新为${_statusLabel(status)}');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('状态更新失败：$error', isError: true);
    }
  }

  Future<void> _confirmDelete(ThemeData themeData) async {
    if (_item.id == null) {
      _showSnackBar('无法删除：进度编号为空', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除进度记录'),
          content: Text(
            '确定删除“${_item.title.trim().isEmpty ? '未命名进度' : _item.title}”吗？此操作不可撤销。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: themeData.colorScheme.error,
                foregroundColor: themeData.colorScheme.onError,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _progressController.deleteProgress(_item.id!);
      if (!mounted) return;
      _showSnackBar('进度记录已删除');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('删除失败：$error', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? '操作失败' : '操作成功',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      backgroundColor: isError
          ? Colors.red.withValues(alpha: 0.12)
          : Colors.green.withValues(alpha: 0.12),
      colorText: Theme.of(context).colorScheme.onSurface,
      duration: const Duration(seconds: 3),
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({
    required this.title,
    required this.status,
    required this.onBack,
  });

  final String title;
  final String status;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: dark ? 0.92 : 0.98),
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: dark ? 0.32 : 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Tooltip(
            message: '返回',
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _StatusToken(status: status),
        ],
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.child,
    this.title,
    this.subtitle,
  });

  final String? title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: dark ? 0.82 : 0.98),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.36 : 0.52),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: dark ? 0.16 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0,
                ),
              ),
            ],
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({required this.fact});

  final _DetailFact fact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = fact.color ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.34 : 0.58,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(fact.icon, color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fact.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  fact.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusToken extends StatelessWidget {
  const _StatusToken({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(status, theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 17, color: color),
          const SizedBox(width: 7),
          Text(
            _statusLabel(status),
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 7),
          Text(
            '$label $value',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.isLast});

  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = step.isDone || step.isCurrent
        ? _statusColor(step.status, theme)
        : scheme.outline;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: step.isCurrent ? 0.20 : 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.54)),
                ),
                child: Icon(
                  step.isDone ? Icons.check_rounded : step.icon,
                  size: 16,
                  color: color,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: scheme.outlineVariant.withValues(alpha: 0.46),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: step.isCurrent ? color : scheme.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    step.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusActionButton extends StatelessWidget {
  const _StatusActionButton({
    required this.label,
    required this.icon,
    required this.status,
    required this.currentStatus,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final String status;
  final String currentStatus;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(status, theme);
    final selected = status == currentStatus;

    return FilledButton.tonalIcon(
      onPressed: enabled && !selected ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(selected ? '${_statusLabel(status)}中' : label),
      style: FilledButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor:
            selected ? color.withValues(alpha: 0.72) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _DetailFact {
  const _DetailFact({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;
}

class _BusinessLink {
  const _BusinessLink({
    required this.label,
    required this.id,
    required this.icon,
  });

  final String label;
  final int id;
  final IconData icon;
}

class _TimelineStep {
  const _TimelineStep({
    required this.title,
    required this.description,
    required this.status,
    required this.icon,
    required this.isDone,
    required this.isCurrent,
  });

  final String title;
  final String description;
  final String status;
  final IconData icon;
  final bool isDone;
  final bool isCurrent;
}

List<_TimelineStep> _timelineSteps(String? status) {
  final normalized = status ?? 'Pending';
  final order = {
    'Pending': 0,
    'Processing': 1,
    'Completed': 2,
    'Archived': 3,
  };
  final currentIndex = order[normalized] ?? 0;

  _TimelineStep step(
    int index,
    String title,
    String description,
    String stepStatus,
    IconData icon,
  ) {
    return _TimelineStep(
      title: title,
      description: description,
      status: stepStatus,
      icon: icon,
      isDone: currentIndex > index,
      isCurrent: currentIndex == index,
    );
  }

  return [
    step(
      0,
      '等待受理',
      '业务已提交，等待管理员核验材料。',
      'Pending',
      Icons.schedule_rounded,
    ),
    step(
      1,
      '正在处理',
      '管理员正在核对业务信息和处理意见。',
      'Processing',
      Icons.sync_rounded,
    ),
    step(
      2,
      '处理完成',
      '业务已有办理结果，可查看详情说明。',
      'Completed',
      Icons.check_circle_outline_rounded,
    ),
    step(
      3,
      '记录归档',
      '该进度已归档，后续作为历史记录留存。',
      'Archived',
      Icons.inventory_2_outlined,
    ),
  ];
}

List<_BusinessLink> _businessLinks(ProgressItem item) {
  return [
    if (item.appealId != null)
      _BusinessLink(
        label: '申诉',
        id: item.appealId!,
        icon: Icons.gavel_rounded,
      ),
    if (item.deductionId != null)
      _BusinessLink(
        label: '扣分',
        id: item.deductionId!,
        icon: Icons.assessment_outlined,
      ),
    if (item.driverId != null)
      _BusinessLink(
        label: '司机',
        id: item.driverId!,
        icon: Icons.badge_outlined,
      ),
    if (item.fineId != null)
      _BusinessLink(
        label: '罚款',
        id: item.fineId!,
        icon: Icons.payments_outlined,
      ),
    if (item.vehicleId != null)
      _BusinessLink(
        label: '车辆',
        id: item.vehicleId!,
        icon: Icons.directions_car_filled_outlined,
      ),
    if (item.offenseId != null)
      _BusinessLink(
        label: '违法',
        id: item.offenseId!,
        icon: Icons.report_problem_outlined,
      ),
  ];
}

String _businessContext(ProgressItem item) {
  final links = _businessLinks(item);
  if (links.isEmpty) return '暂无关联业务记录';
  return links.map((link) => '${link.label} #${link.id}').join(' / ');
}

String _formatDetails(String? rawDetails) {
  final details = rawDetails?.trim();
  if (details == null || details.isEmpty) {
    return '暂无详情内容。';
  }

  try {
    final decoded = jsonDecode(details);
    if (decoded is Map || decoded is List) {
      return const JsonEncoder.withIndent('  ').convert(decoded);
    }
    return decoded.toString();
  } catch (_) {
    return details;
  }
}

String _formatDateTime(DateTime dateTime) {
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
}

String _emptyFallback(String? value, String fallback) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? fallback : normalized;
}

String _statusLabel(String? status) {
  switch (status) {
    case 'Pending':
      return '待处理';
    case 'Processing':
      return '处理中';
    case 'Completed':
      return '已完成';
    case 'Archived':
      return '已归档';
    default:
      return '未知状态';
  }
}

IconData _statusIcon(String? status) {
  switch (status) {
    case 'Pending':
      return Icons.schedule_rounded;
    case 'Processing':
      return Icons.sync_rounded;
    case 'Completed':
      return Icons.check_circle_outline_rounded;
    case 'Archived':
      return Icons.inventory_2_outlined;
    default:
      return Icons.help_outline_rounded;
  }
}

Color _statusColor(String? status, ThemeData themeData) {
  final scheme = themeData.colorScheme;
  final dark = themeData.brightness == Brightness.dark;

  switch (status) {
    case 'Pending':
      return dark ? const Color(0xFFEAB45C) : const Color(0xFF996A16);
    case 'Processing':
      return scheme.primary;
    case 'Completed':
      return dark ? const Color(0xFF75D78C) : const Color(0xFF227447);
    case 'Archived':
      return scheme.onSurfaceVariant;
    default:
      return scheme.outline;
  }
}
