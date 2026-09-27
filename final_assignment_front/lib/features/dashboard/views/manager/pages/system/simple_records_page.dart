import 'package:flutter/material.dart';

const _pageSize = 20;

class SimpleRecordsPage extends StatefulWidget {
  const SimpleRecordsPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.columns,
    required this.load,
  });

  final String title;
  final String subtitle;
  final List<String> columns;
  final Future<List<Map<String, String>>> Function() load;

  @override
  State<SimpleRecordsPage> createState() => _SimpleRecordsPageState();
}

class _SimpleRecordsPageState extends State<SimpleRecordsPage> {
  late Future<List<Map<String, String>>> _future = widget.load();
  String _query = '';
  int _page = 0;
  Map<String, String>? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(widget.subtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: '筛选'),
            onChanged: (value) => setState(() {
              _query = value.trim();
              _page = 0;
            }),
          ),
          if (_query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InputChip(
                label: Text('筛选：$_query'),
                onDeleted: () => setState(() {
                  _query = '';
                  _page = 0;
                }),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Map<String, String>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: Text('正在加载，请稍候。'));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('列表没有加载成功。筛选条件会保留，可以重试。'),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => setState(() => _future = widget.load()),
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                }
                final rows = (snapshot.data ?? []).where((row) {
                  if (_query.isEmpty) return true;
                  return row.values.any((value) => value.contains(_query));
                }).toList();
                if (rows.isEmpty) {
                  return const Center(child: Text('暂无记录。可以清除筛选后再看。'));
                }
                final pageCount = (rows.length / _pageSize).ceil();
                final currentPage = _page >= pageCount ? pageCount - 1 : _page;
                final start = currentPage * _pageSize;
                final end = start + _pageSize > rows.length ? rows.length : start + _pageSize;
                final pageRows = rows.sublist(start, end);
                return Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final minWidth = widget.columns.length * 140.0;
                                final width = constraints.maxWidth < minWidth ? minWidth : constraints.maxWidth;
                                return Scrollbar(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: width,
                                      child: Column(
                                        children: [
                                          Container(
                                            height: 44,
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Row(
                                              children: [
                                                for (final column in widget.columns)
                                                  Expanded(
                                                    child: Text(
                                                      column,
                                                      style: theme.textTheme.bodyMedium?.copyWith(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w700,
                                                        color: theme.colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: ListView.builder(
                                              itemCount: pageRows.length,
                                              itemBuilder: (context, index) {
                                                final row = pageRows[index];
                                                return InkWell(
                                                  onTap: () => setState(() => _selected = row),
                                                  child: Container(
                                                    constraints: const BoxConstraints(minHeight: 44),
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        for (final column in widget.columns)
                                                          Expanded(
                                                            child: Text(
                                                              row[column] ?? '',
                                                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                                                            ),
                                                          ),
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
                            ),
                          ),
                          if (_selected != null)
                            SizedBox(
                              width: 280,
                              child: ListView(
                                padding: const EdgeInsets.all(12),
                                children: [
                                  Text('记录详情', style: theme.textTheme.titleMedium),
                                  for (final column in widget.columns)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text('$column：${_selected![column] ?? "—"}'),
                                    ),
                                  TextButton(
                                    onPressed: () => setState(() => _selected = null),
                                    child: const Text('关闭'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Text('第 ${currentPage + 1} / $pageCount 页'),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: currentPage == 0 ? null : () => setState(() => _page = currentPage - 1),
                            child: const Text('上一页'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: currentPage >= pageCount - 1
                                ? null
                                : () => setState(() => _page = currentPage + 1),
                            child: const Text('下一页'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
