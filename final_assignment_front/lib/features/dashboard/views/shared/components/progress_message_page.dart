import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:final_assignment_front/shared/widgets/index.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

typedef ProgressItemCallback = void Function(ProgressItem item);
typedef ProgressStatusCallback = void Function(
    ProgressItem item, String status);
typedef ProgressContextBuilder = String Function(ProgressItem item);

class ProgressMessagePageBody extends StatelessWidget {
  const ProgressMessagePageBody({
    super.key,
    required this.title,
    required this.subtitle,
    required this.roleLabel,
    required this.items,
    required this.totalCount,
    required this.statusCategories,
    required this.isLoading,
    required this.errorMessage,
    required this.hasAccess,
    required this.emptyMessage,
    required this.businessContextBuilder,
    required this.onStatusSelected,
    required this.onDateRangePressed,
    required this.onClearFilters,
    required this.onOpen,
    this.selectedStatus,
    this.selectedStartDate,
    this.selectedEndDate,
    this.permissionHint,
    this.onRefresh,
    this.onRetry,
    this.onCreate,
    this.onEdit,
    this.onDelete,
    this.onStatusChange,
  });

  final String title;
  final String subtitle;
  final String roleLabel;
  final List<ProgressItem> items;
  final int totalCount;
  final List<String> statusCategories;
  final bool isLoading;
  final String errorMessage;
  final bool hasAccess;
  final String emptyMessage;
  final String? selectedStatus;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final String? permissionHint;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onRetry;
  final VoidCallback? onCreate;
  final ProgressItemCallback onOpen;
  final ProgressItemCallback? onEdit;
  final ProgressItemCallback? onDelete;
  final ProgressStatusCallback? onStatusChange;
  final ProgressContextBuilder businessContextBuilder;
  final ValueChanged<String> onStatusSelected;
  final VoidCallback onDateRangePressed;
  final VoidCallback onClearFilters;

  bool get _hasDateFilter =>
      selectedStartDate != null && selectedEndDate != null;

  bool get _hasActiveFilter =>
      (selectedStatus != null && selectedStatus!.isNotEmpty) || _hasDateFilter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = width < 520 ? 12.0 : 20.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProgressMessageHeader(
                title: title,
                subtitle: subtitle,
                roleLabel: roleLabel,
                totalCount: totalCount,
                currentCount: items.length,
                activeFilterLabel: _activeFilterLabel(),
                onRefresh: onRefresh,
              ),
              const SizedBox(height: 12),
              ProgressFilterBar(
                statusCategories: statusCategories,
                selectedStatus: selectedStatus,
                selectedStartDate: selectedStartDate,
                selectedEndDate: selectedEndDate,
                hasActiveFilter: _hasActiveFilter,
                onStatusSelected: onStatusSelected,
                onDateRangePressed: onDateRangePressed,
                onClearFilters: onClearFilters,
                onCreate: onCreate,
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildContent(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const ProgressStatePanel(
        child: LoadingView(message: '正在加载进度消息'),
      );
    }

    if (!hasAccess) {
      return ProgressStatePanel(
        child: PermissionDeniedView(
          hint: permissionHint ?? '权限不足：当前账号无法访问进度消息',
        ),
      );
    }

    if (errorMessage.trim().isNotEmpty) {
      return ProgressStatePanel(
        child: ErrorStateView(
          message: errorMessage,
          onRetry: onRetry == null ? null : () => onRetry!.call(),
        ),
      );
    }

    if (items.isEmpty) {
      return ProgressStatePanel(
        child: EmptyStateView(
          message: emptyMessage,
          icon: Icons.mark_email_unread_outlined,
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: RefreshIndicator(
        onRefresh: onRetry ?? () async {},
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = items[index];
            return ProgressMessageCard(
              item: item,
              businessContext: businessContextBuilder(item),
              statusCategories: statusCategories,
              onOpen: onOpen,
              onEdit: onEdit,
              onDelete: onDelete,
              onStatusChange: onStatusChange,
            );
          },
        ),
      ),
    );
  }

  String? _activeFilterLabel() {
    if (_hasDateFilter) {
      return '${_shortDate(selectedStartDate!)} - ${_shortDate(selectedEndDate!)}';
    }
    if (selectedStatus != null && selectedStatus!.isNotEmpty) {
      return progressStatusLabel(selectedStatus);
    }
    return null;
  }
}

class ProgressMessageHeader extends StatelessWidget {
  const ProgressMessageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.roleLabel,
    required this.totalCount,
    required this.currentCount,
    this.activeFilterLabel,
    this.onRefresh,
  });

  final String title;
  final String subtitle;
  final String roleLabel;
  final int totalCount;
  final int currentCount;
  final String? activeFilterLabel;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: dark ? 0.88 : 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.42 : 0.56),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: dark ? 0.16 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 660;
          final summary = Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _ProgressSummaryPill(label: '全部', value: totalCount.toString()),
              _ProgressSummaryPill(
                label: '当前显示',
                value: currentCount.toString(),
              ),
              if (activeFilterLabel != null)
                _ProgressSummaryPill(label: '筛选', value: activeFilterLabel!),
            ],
          );

          final heading = Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.76),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.timeline_rounded,
                  color: scheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _RoleBadge(label: roleLabel),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRefresh != null) ...[
                const SizedBox(width: 10),
                Tooltip(
                  message: '刷新',
                  child: IconButton.filledTonal(
                    onPressed: () => onRefresh!.call(),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                  ),
                ),
              ],
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                const SizedBox(height: 14),
                summary,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: heading),
              const SizedBox(width: 16),
              summary,
            ],
          );
        },
      ),
    );
  }
}

class ProgressFilterBar extends StatelessWidget {
  const ProgressFilterBar({
    super.key,
    required this.statusCategories,
    required this.hasActiveFilter,
    required this.onStatusSelected,
    required this.onDateRangePressed,
    required this.onClearFilters,
    this.selectedStatus,
    this.selectedStartDate,
    this.selectedEndDate,
    this.onCreate,
  });

  final List<String> statusCategories;
  final String? selectedStatus;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final bool hasActiveFilter;
  final ValueChanged<String> onStatusSelected;
  final VoidCallback onDateRangePressed;
  final VoidCallback onClearFilters;
  final VoidCallback? onCreate;

  bool get _hasDateFilter =>
      selectedStartDate != null && selectedEndDate != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer.withValues(alpha: dark ? 0.42 : 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.34 : 0.5),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          final chips = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('全部'),
                selected: !hasActiveFilter,
                onSelected: (_) => onClearFilters(),
              ),
              for (final status in statusCategories)
                FilterChip(
                  label: Text(progressStatusLabel(status)),
                  selected: selectedStatus == status,
                  onSelected: (_) => onStatusSelected(status),
                  avatar: Icon(
                    progressStatusIcon(status),
                    size: 16,
                    color: selectedStatus == status
                        ? scheme.onPrimary
                        : progressStatusColor(status, theme),
                  ),
                ),
            ],
          );

          final dateButton = OutlinedButton.icon(
            onPressed: onDateRangePressed,
            icon: const Icon(Icons.date_range_rounded, size: 18),
            label: Text(
              _dateFilterLabel(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
          final clearButton = IconButton.filledTonal(
            onPressed: hasActiveFilter ? onClearFilters : null,
            icon: const Icon(Icons.filter_alt_off_rounded, size: 20),
            tooltip: '清除筛选',
          );
          final createButton = onCreate == null
              ? null
              : FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text('新建进度'),
                );
          final actions = compact
              ? Row(
                  children: [
                    Expanded(child: dateButton),
                    const SizedBox(width: 8),
                    clearButton,
                    if (createButton != null) ...[
                      const SizedBox(width: 8),
                      Expanded(child: createButton),
                    ],
                  ],
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    dateButton,
                    clearButton,
                    if (createButton != null) createButton,
                  ],
                );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                chips,
                const SizedBox(height: 10),
                actions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: chips),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }

  String _dateFilterLabel() {
    if (!_hasDateFilter) return '时间范围';
    return '${_shortDate(selectedStartDate!)} - ${_shortDate(selectedEndDate!)}';
  }
}

class ProgressMessageCard extends StatefulWidget {
  const ProgressMessageCard({
    super.key,
    required this.item,
    required this.businessContext,
    required this.statusCategories,
    required this.onOpen,
    this.onEdit,
    this.onDelete,
    this.onStatusChange,
  });

  final ProgressItem item;
  final String businessContext;
  final List<String> statusCategories;
  final ProgressItemCallback onOpen;
  final ProgressItemCallback? onEdit;
  final ProgressItemCallback? onDelete;
  final ProgressStatusCallback? onStatusChange;

  @override
  State<ProgressMessageCard> createState() => _ProgressMessageCardState();
}

class _ProgressMessageCardState extends State<ProgressMessageCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final statusColor = progressStatusColor(widget.item.status, theme);
    final details = widget.item.details?.trim();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onOpen(widget.item),
          borderRadius: BorderRadius.circular(8),
          splashColor: statusColor.withValues(alpha: 0.09),
          highlightColor: statusColor.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color.lerp(
                scheme.surface,
                statusColor,
                _hovered ? (dark ? 0.08 : 0.035) : 0,
              )!
                  .withValues(alpha: dark ? 0.88 : 0.98),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hovered
                    ? statusColor.withValues(alpha: dark ? 0.56 : 0.42)
                    : scheme.outlineVariant.withValues(
                        alpha: dark ? 0.38 : 0.54,
                      ),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(
                    alpha: _hovered ? (dark ? 0.22 : 0.09) : 0.04,
                  ),
                  blurRadius: _hovered ? 18 : 10,
                  offset: Offset(0, _hovered ? 10 : 6),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatusIconBox(status: widget.item.status),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.item.title.isEmpty
                                          ? '未命名进度'
                                          : widget.item.title,
                                      maxLines: compact ? 2 : 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: scheme.onSurface,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                                  if (!compact) ...[
                                    const SizedBox(width: 10),
                                    _StatusBadge(status: widget.item.status),
                                  ],
                                ],
                              ),
                              if (compact) ...[
                                const SizedBox(height: 8),
                                _StatusBadge(status: widget.item.status),
                              ],
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _MetaPill(
                                    icon: Icons.schedule_rounded,
                                    label: DateFormat('yyyy-MM-dd HH:mm')
                                        .format(widget.item.submitTime),
                                  ),
                                  if (widget.item.username.trim().isNotEmpty)
                                    _MetaPill(
                                      icon: Icons.person_outline_rounded,
                                      label: widget.item.username,
                                    ),
                                  _MetaPill(
                                    icon: Icons.link_rounded,
                                    label: widget.businessContext,
                                  ),
                                ],
                              ),
                              if (details != null && details.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  details,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.42,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ProgressCardMenu(
                          item: widget.item,
                          statusCategories: widget.statusCategories,
                          onOpen: widget.onOpen,
                          onEdit: widget.onEdit,
                          onDelete: widget.onDelete,
                          onStatusChange: widget.onStatusChange,
                        ),
                      ],
                    ),
                  ],
                );

                return content;
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressStatePanel extends StatelessWidget {
  const ProgressStatePanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: dark ? 0.72 : 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.36 : 0.52),
        ),
      ),
      child: child,
    );
  }
}

class _ProgressCardMenu extends StatelessWidget {
  const _ProgressCardMenu({
    required this.item,
    required this.statusCategories,
    required this.onOpen,
    this.onEdit,
    this.onDelete,
    this.onStatusChange,
  });

  final ProgressItem item;
  final List<String> statusCategories;
  final ProgressItemCallback onOpen;
  final ProgressItemCallback? onEdit;
  final ProgressItemCallback? onDelete;
  final ProgressStatusCallback? onStatusChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopupMenuButton<String>(
      tooltip: '更多操作',
      icon: Icon(Icons.more_horiz_rounded, color: scheme.onSurfaceVariant),
      onSelected: (value) {
        if (value == 'view') {
          onOpen(item);
        } else if (value == 'edit') {
          onEdit?.call(item);
        } else if (value == 'delete') {
          onDelete?.call(item);
        } else if (value.startsWith('status:')) {
          onStatusChange?.call(item, value.substring('status:'.length));
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            value: 'view',
            child: _MenuRow(
              icon: Icons.visibility_outlined,
              label: '查看详情',
              color: scheme.onSurface,
            ),
          ),
          if (onEdit != null)
            PopupMenuItem(
              value: 'edit',
              child: _MenuRow(
                icon: Icons.edit_outlined,
                label: '编辑',
                color: scheme.onSurface,
              ),
            ),
          if (onStatusChange != null) const PopupMenuDivider(),
          if (onStatusChange != null)
            for (final status in statusCategories)
              PopupMenuItem(
                value: 'status:$status',
                enabled: item.status != status,
                child: _MenuRow(
                  icon: progressStatusIcon(status),
                  label: '设为${progressStatusLabel(status)}',
                  color: item.status == status
                      ? scheme.onSurfaceVariant
                      : progressStatusColor(status, theme),
                ),
              ),
          if (onDelete != null) const PopupMenuDivider(),
          if (onDelete != null)
            PopupMenuItem(
              value: 'delete',
              child: _MenuRow(
                icon: Icons.delete_outline_rounded,
                label: '删除',
                color: scheme.error,
              ),
            ),
        ];
      },
    );
  }
}

class _StatusIconBox extends StatelessWidget {
  const _StatusIconBox({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = progressStatusColor(status, theme);

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(progressStatusIcon(status), color: color, size: 22),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = progressStatusColor(status, theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        progressStatusLabel(status),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label.isEmpty ? '无关联业务' : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSummaryPill extends StatelessWidget {
  const _ProgressSummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

String progressStatusLabel(String? status) {
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
      return '未知';
  }
}

IconData progressStatusIcon(String? status) {
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

Color progressStatusColor(String? status, ThemeData themeData) {
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

String _shortDate(DateTime date) {
  return DateFormat('MM-dd').format(date);
}
