import 'package:final_assignment_front/features/api/rag_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/bindings/manager_dashboard_binding.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RagManagementPage extends StatefulWidget {
  const RagManagementPage({super.key});

  @override
  State<RagManagementPage> createState() => _RagManagementPageState();
}

class _RagManagementPageState extends State<RagManagementPage> {
  final RagManagementControllerApi api = RagManagementControllerApi();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController queryController = TextEditingController();
  late ManagerDashboardController controller;

  RagOverview? overview;
  List<RagDocumentDto> documents = const [];
  bool loading = true;
  bool saving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    DashboardBinding.registerDependencies();
    controller = Get.find<ManagerDashboardController>();
    _load();
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    queryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      await api.initializeWithJwt();
      final nextOverview = await api.getOverview();
      final nextDocuments = await api.listDocuments(
        query: queryController.text,
      );
      if (!mounted) return;
      setState(() {
        overview = nextOverview;
        documents = nextDocuments;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _submit() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      _showSnack('请填写资料标题和内容', isError: true);
      return;
    }
    setState(() => saving = true);
    try {
      await api.createManualDocument(title: title, content: content);
      titleController.clear();
      contentController.clear();
      _showSnack('RAG 资料已录入');
      await _load();
    } catch (error) {
      _showSnack('录入失败：$error', isError: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _runBackfill() async {
    setState(() => saving = true);
    try {
      await api.runBackfill();
      _showSnack('已触发一批 RAG 回填');
      await _load();
    } catch (error) {
      _showSnack('回填失败：$error', isError: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _deleteDocument(RagDocumentDto document) async {
    setState(() => saving = true);
    try {
      await api.deleteDocument(document.id);
      _showSnack('资料已删除');
      await _load();
    } catch (error) {
      _showSnack('删除失败：$error', isError: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return DashboardPageTemplate(
        theme: themeData,
        title: 'RAG 资料管理',
        pageType: DashboardPageType.manager,
        onRefresh: _load,
        bodyIsScrollable: true,
        isLoading: loading,
        errorMessage: errorMessage,
        body: _buildBody(themeData),
      );
    });
  }

  Widget _buildBody(ThemeData themeData) {
    final scheme = themeData.colorScheme;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _buildOverview(themeData),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 860;
            final form = _buildInputPanel(themeData);
            final list = _buildDocumentPanel(themeData);
            if (narrow) {
              return Column(
                children: [
                  form,
                  const SizedBox(height: 14),
                  list,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 360, child: form),
                const SizedBox(width: 14),
                Expanded(child: list),
              ],
            );
          },
        ),
        if (overview != null &&
            (!overview!.ragEnabled || !overview!.indexingEnabled)) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
            ),
            child: Text(
              'RAG 或索引能力未启用，请检查后端 rag.enabled / rag.indexing.enabled 配置。',
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOverview(ThemeData themeData) {
    final overview = this.overview;
    final metrics = [
      ('资料', overview?.documentCount ?? 0, Icons.library_books_rounded),
      ('READY', overview?.readyDocumentCount ?? 0, Icons.verified_rounded),
      ('切片', overview?.chunkCount ?? 0, Icons.segment_rounded),
      ('待向量', overview?.pendingEmbeddingTaskCount ?? 0, Icons.pending_actions),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: metrics
          .map((metric) => _MetricPill(
                label: metric.$1,
                value: metric.$2,
                icon: metric.$3,
              ))
          .toList(growable: false),
    );
  }

  Widget _buildInputPanel(ThemeData themeData) {
    final scheme = themeData.colorScheme;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '录入资料',
            style: themeData.textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: '资料标题',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: contentController,
            minLines: 8,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: '资料正文',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: saving ? null : _submit,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(saving ? '处理中' : '录入并切片'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: saving ? null : _runBackfill,
                tooltip: '回填业务资料',
                icon: const Icon(Icons.sync_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPanel(ThemeData themeData) {
    final scheme = themeData.colorScheme;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: queryController,
                  onSubmitted: (_) => _load(),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: '搜索资料标题或来源',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _load,
                tooltip: '刷新',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (documents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 44),
              child: Center(
                child: Text(
                  '暂无 RAG 资料',
                  style: themeData.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            ...documents.map(
              (document) => _DocumentTile(
                document: document,
                onDelete: saving ? null : () => _deleteDocument(document),
              ),
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: dark ? 0.78 : 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.36 : 0.48),
        ),
      ),
      child: child,
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                    )),
                Text(label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.document,
    required this.onDelete,
  });

  final RagDocumentDto document;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.article_outlined, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${document.sourceType} · ${document.sourceId} · ${document.status}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: '删除资料',
            icon: Icon(Icons.delete_outline, color: scheme.error),
          ),
        ],
      ),
    );
  }
}
