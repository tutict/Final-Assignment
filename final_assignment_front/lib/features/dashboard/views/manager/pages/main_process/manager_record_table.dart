import 'dart:math' as math;

import 'package:flutter/material.dart';

class ManagerRecordAction {
  const ManagerRecordAction({
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool danger;
}

class ManagerTableCell {
  const ManagerTableCell({
    required this.label,
    required this.value,
    this.child,
  });

  final String label;
  final String value;
  final Widget? child;
}

class ManagerTableRow {
  const ManagerTableRow({
    required this.cells,
    this.actions = const [],
  });

  final List<ManagerTableCell> cells;
  final List<ManagerRecordAction> actions;
}

class ManagerTablePager extends StatelessWidget {
  const ManagerTablePager({
    super.key,
    required this.page,
    required this.onPage,
    this.pageCount,
    this.hasNext = false,
  });

  final int page;
  final int? pageCount;
  final bool hasNext;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canPrev = page > 1;
    final canNext = pageCount != null ? page < pageCount! : hasNext;
    final label = pageCount == null ? '第 $page 页' : '第 $page / $pageCount 页';
    final style = TextButton.styleFrom(
      foregroundColor: scheme.primary,
      disabledForegroundColor: scheme.onSurface,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          TextButton(
            onPressed: canPrev ? () => onPage(page - 1) : null,
            style: style,
            child: const Text('上一页'),
          ),
          TextButton(
            onPressed: canNext ? () => onPage(page + 1) : null,
            style: style,
            child: const Text('下一页'),
          ),
        ],
      ),
    );
  }
}

class ManagerRecordTable extends StatefulWidget {
  const ManagerRecordTable({
    super.key,
    required this.rows,
    this.columns = const [],
    this.pageSize = 20,
    this.page,
    this.hasNext = false,
    this.onPage,
  });

  final List<ManagerTableRow> rows;
  final List<String> columns;
  final int pageSize;
  final int? page;
  final bool hasNext;
  final ValueChanged<int>? onPage;

  bool get controlled => onPage != null && page != null;

  @override
  State<ManagerRecordTable> createState() => _ManagerRecordTableState();
}

class _ManagerRecordTableState extends State<ManagerRecordTable> {
  int _page = 1;
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final labels = widget.rows.isNotEmpty
        ? widget.rows.first.cells.map((cell) => cell.label).toList()
        : widget.columns;
    final controlled = widget.controlled;
    final pageCount = math.max(1, (widget.rows.length / widget.pageSize).ceil());
    final page = controlled ? widget.page! : _page.clamp(1, pageCount);
    final start = controlled ? 0 : (page - 1) * widget.pageSize;
    final visible = controlled
        ? widget.rows
        : widget.rows.skip(start).take(widget.pageSize).toList();
    final selected = _selectedIndex != null &&
            _selectedIndex! >= 0 &&
            _selectedIndex! < widget.rows.length
        ? widget.rows[_selectedIndex!]
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final table = Column(
          children: [
            Expanded(
              child: widget.rows.isEmpty
                  ? const Center(child: Text('暂无记录。可以调整筛选，或使用页面上的主操作新增。'))
                  : _TableSheet(
                      labels: labels,
                      rows: visible,
                      startIndex: start,
                      selectedIndex: _selectedIndex,
                      onRow: (index) => setState(() => _selectedIndex = index),
                    ),
            ),
            ManagerTablePager(
              page: page,
              pageCount: controlled ? null : pageCount,
              hasNext: widget.hasNext,
              onPage: (next) {
                if (controlled) {
                  widget.onPage!(next);
                  return;
                }
                setState(() {
                  _page = next;
                  _selectedIndex = null;
                });
              },
            ),
            if (!wide && selected != null)
              SizedBox(height: 280, child: _DetailPanel(row: selected, onClose: _clearSelection)),
          ],
        );

        if (!wide || selected == null) return table;
        return Row(
          children: [
            Expanded(child: table),
            const SizedBox(width: 12),
            SizedBox(
              width: 320,
              child: _DetailPanel(row: selected, onClose: _clearSelection),
            ),
          ],
        );
      },
    );
  }

  void _clearSelection() => setState(() => _selectedIndex = null);
}

class _TableSheet extends StatelessWidget {
  const _TableSheet({
    required this.labels,
    required this.rows,
    required this.startIndex,
    required this.selectedIndex,
    required this.onRow,
  });

  final List<String> labels;
  final List<ManagerTableRow> rows;
  final int startIndex;
  final int? selectedIndex;
  final ValueChanged<int> onRow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(constraints.maxWidth, labels.length * 148.0 + 96);
        return Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: Column(
                children: [
                  _Header(labels: labels),
                  Expanded(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        final absolute = startIndex + index;
                        final selected = selectedIndex == absolute;
                        return InkWell(
                          onTap: () => onRow(absolute),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 44),
                            color: selected ? scheme.primary.withValues(alpha: 0.08) : null,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: scheme.outlineVariant),
                              ),
                            ),
                            child: Row(
                              children: [
                                for (final cell in row.cells)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      child: cell.child ??
                                          Text(
                                            cell.value,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
                                          ),
                                    ),
                                  ),
                                _RowActions(actions: row.actions),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      color: scheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final label in labels)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 148),
        ],
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({required this.actions});

  final List<ManagerRecordAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox(width: 148);
    if (actions.length > 2) {
      return PopupMenuButton<int>(
        tooltip: '操作',
        onSelected: (index) => actions[index].onPressed(),
        itemBuilder: (context) => [
          for (var i = 0; i < actions.length; i++)
            PopupMenuItem<int>(
              value: i,
              child: Text(actions[i].label),
            ),
        ],
        child: const SizedBox(
          width: 148,
          height: 44,
          child: Center(child: Text('操作')),
        ),
      );
    }

    return SizedBox(
      width: 148,
      child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (final action in actions)
          TextButton(
            onPressed: action.onPressed,
            style: TextButton.styleFrom(
              foregroundColor: action.danger ? Theme.of(context).colorScheme.error : null,
              minimumSize: const Size(0, 44),
            ),
            child: Text(action.label),
          ),
      ],
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.row, required this.onClose});

  final ManagerTableRow row;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '记录详情',
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: '关闭详情',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final cell in row.cells) ...[
                  Text(cell.label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(cell.value, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.5)),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  children: [
                    for (final action in row.actions)
                      TextButton(onPressed: action.onPressed, child: Text(action.label)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
