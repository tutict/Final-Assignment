import 'dart:convert';

import 'package:final_assignment_front/features/api/rag_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/bindings/manager_dashboard_binding.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'rag_file_picker.dart';

class RagManagementPage extends StatefulWidget {
  const RagManagementPage({super.key});

  @override
  State<RagManagementPage> createState() => _RagManagementPageState();
}

class _RagManagementPageState extends State<RagManagementPage> {
  final RagManagementControllerApi api = RagManagementControllerApi();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController queryController = TextEditingController();
  final TextEditingController sourceIdController = TextEditingController();
  final TextEditingController sourceVersionController = TextEditingController();
  final TextEditingController routeController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  final TextEditingController sourceUrlController = TextEditingController();
  final TextEditingController metadataController = TextEditingController();
  final TextEditingController previewQueryController = TextEditingController();
  late ManagerDashboardController controller;

  RagOverview? overview;
  List<RagDocumentDto> documents = const [];
  List<RagPreviewHit> previewHits = const [];
  int page = 1;
  int pageSize = 20;
  int documentTotal = 0;
  bool loading = true;
  bool saving = false;
  bool uploading = false;
  bool previewing = false;
  String? errorMessage;
  String selectedAclScope = 'PUBLIC';
  String previewRole = 'USER';
  PickedRagFile? selectedUploadFile;

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
    sourceIdController.dispose();
    sourceVersionController.dispose();
    routeController.dispose();
    categoryController.dispose();
    tagsController.dispose();
    sourceUrlController.dispose();
    metadataController.dispose();
    previewQueryController.dispose();
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
        page: page,
        size: pageSize,
      );
      if (!mounted) return;
      setState(() {
        overview = nextOverview;
        documents = nextDocuments.items;
        documentTotal = nextDocuments.total;
        page = nextDocuments.page;
        pageSize = nextDocuments.size == 0 ? pageSize : nextDocuments.size;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }
    final title = titleController.text.trim();
    final content = contentController.text.trim();
    final metadataJson = _buildMetadataJson();
    if (metadataJson == null) {
      return;
    }
    setState(() => saving = true);
    try {
      final result = await api.createManualDocument(
        sourceId: sourceIdController.text,
        sourceVersion: sourceVersionController.text,
        title: title,
        content: content,
        aclScope: selectedAclScope,
        route: routeController.text,
        metadataJson: metadataJson,
      );
      if (!mounted) return;
      _clearForm();
      _showSnack('RAG 资料已录入');
      await _load();
      if (mounted) {
        _showSnack(
          '已生成 ${result.chunkCount} 个切片，${result.embeddingTaskCount} 个向量任务',
        );
      }
    } catch (error) {
      _showSnack('录入失败：$error', isError: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String? _buildMetadataJson() {
    final metadata = <String, dynamic>{
      'ingestMode': 'manual',
      'category': categoryController.text.trim(),
      'tags': _splitTags(tagsController.text),
      'sourceUrl': sourceUrlController.text.trim(),
    }..removeWhere((_, value) {
        if (value == null) return true;
        if (value is String) return value.trim().isEmpty;
        if (value is Iterable) return value.isEmpty;
        return false;
      });

    final extra = metadataController.text.trim();
    if (extra.isNotEmpty) {
      try {
        final decoded = jsonDecode(extra);
        if (decoded is! Map<String, dynamic>) {
          _showSnack('额外元数据必须是 JSON 对象', isError: true);
          return null;
        }
        metadata.addAll(decoded);
      } catch (_) {
        _showSnack('额外元数据不是有效 JSON', isError: true);
        return null;
      }
    }

    return jsonEncode(metadata.isEmpty ? <String, dynamic>{} : metadata);
  }

  List<String> _splitTags(String value) {
    return value
        .split(RegExp(r'[,，;；\s]+'))
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  void _clearForm() {
    setState(() {
      titleController.clear();
      contentController.clear();
      sourceIdController.clear();
      sourceVersionController.clear();
      routeController.clear();
      categoryController.clear();
      tagsController.clear();
      sourceUrlController.clear();
      metadataController.clear();
      selectedAclScope = 'PUBLIC';
      selectedUploadFile = null;
    });
    formKey.currentState?.reset();
  }

  void _applyTemplate(_RagTemplate template) {
    setState(() {
      titleController.text = template.title;
      contentController.text = template.content;
      categoryController.text = template.category;
      tagsController.text = template.tags.join('，');
      routeController.text = template.route;
      selectedAclScope = template.aclScope;
      sourceVersionController.text =
          'v${DateTime.now().millisecondsSinceEpoch}';
    });
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

  Future<void> _runEmbedding() async {
    setState(() => saving = true);
    try {
      await api.runEmbeddingBatch();
      _showSnack('已执行一批向量任务');
      await _load();
    } catch (error) {
      _showSnack('向量任务失败：$error', isError: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _requeueEmbedding() async {
    setState(() => saving = true);
    try {
      await api.requeueEmbeddingTasks();
      _showSnack('已重新入队向量任务');
      await _load();
    } catch (error) {
      _showSnack('重新入队失败：$error', isError: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _migrateIndex() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('迁移 RAG 索引？'),
        content: const Text('将创建新索引并切换别名，可能短暂影响检索。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('确认迁移')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => saving = true);
    try {
      await api.migrateIndex();
      _showSnack('已触发索引迁移');
      await _load();
    } catch (error) {
      _showSnack('索引迁移失败：$error', isError: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _runPreview() async {
    final query = previewQueryController.text.trim();
    if (query.isEmpty) {
      _showSnack('请输入试检索问题', isError: true);
      return;
    }
    setState(() => previewing = true);
    try {
      final hits = await api.preview(query: query, asRole: previewRole);
      if (!mounted) return;
      setState(() => previewHits = hits);
    } catch (error) {
      _showSnack('试检索失败：$error', isError: true);
    } finally {
      if (mounted) setState(() => previewing = false);
    }
  }

  Future<void> _openDocument(RagDocumentDto document) async {
    try {
      final detail = await api.getDocument(document.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => _DocumentDetailSheet(
          detail: detail,
          onSave: (title, content, acl, route) async {
            final result = await api.updateDocument(
              documentId: document.id,
              title: title,
              content: content,
              aclScope: acl,
              route: route,
              metadataJson: document.metadataJson,
            );
            if (!mounted) return;
            Navigator.pop(context);
            _showSnack(
              '已重索引：${result.chunkCount} 个切片，${result.embeddingTaskCount} 个向量任务',
            );
            await _load();
          },
        ),
      );
    } catch (error) {
      _showSnack('打开资料失败：$error', isError: true);
    }
  }

  Future<void> _selectUploadFile() async {
    try {
      final picked = await _pickRagFile();
      if (picked == null || !mounted) return;
      setState(() {
        selectedUploadFile = picked;
        if (titleController.text.trim().isEmpty) {
          titleController.text = picked.title;
        }
        if (sourceVersionController.text.trim().isEmpty) {
          sourceVersionController.text =
              'v${DateTime.now().millisecondsSinceEpoch}';
        }
      });
    } catch (error) {
      _showSnack('选择文件失败：$error', isError: true);
    }
  }

  Future<PickedRagFile?> _pickRagFile() => pickRagFile();

  Future<void> _uploadSelectedFile() async {
    final file = selectedUploadFile;
    if (file == null) {
      _showSnack('请先选择文档或表格', isError: true);
      return;
    }
    final metadataJson = _buildMetadataJson();
    if (metadataJson == null) return;

    setState(() => uploading = true);
    try {
      final result = await api.uploadDocument(
        fileName: file.name,
        bytes: file.bytes,
        sourceId: sourceIdController.text,
        sourceVersion: sourceVersionController.text,
        title: titleController.text,
        aclScope: selectedAclScope,
        route: routeController.text,
        metadataJson: metadataJson,
      );
      if (!mounted) return;
      setState(() => selectedUploadFile = null);
      _clearForm();
      _showSnack(
        '文件已录入，生成 ${result.chunkCount} 个切片，${result.embeddingTaskCount} 个向量任务',
      );
      await _load();
    } catch (error) {
      _showSnack('上传录入失败：$error', isError: true);
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _deleteDocument(RagDocumentDto document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除 RAG 资料？'),
        content: Text('将删除「${document.title}」及其切片和向量任务，且不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('确认删除')),
        ],
      ),
    );
    if (confirmed != true) return;
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
      ('失败任务', overview?.failedEmbeddingTaskCount ?? 0, Icons.error_outline),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: metrics
              .map((metric) => _MetricPill(
                    label: metric.$1,
                    value: metric.$2,
                    icon: metric.$3,
                  ))
              .toList(growable: false),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: saving ? null : _runEmbedding,
              icon: const Icon(Icons.memory_rounded),
              label: const Text('跑一批向量'),
            ),
            OutlinedButton.icon(
              onPressed: saving ? null : _requeueEmbedding,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('重新入队'),
            ),
            OutlinedButton.icon(
              onPressed: saving ? null : _migrateIndex,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('迁索引'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputPanel(ThemeData themeData) {
    final scheme = themeData.colorScheme;
    final charCount = contentController.text.characters.length;
    final estimatedChunks = charCount == 0 ? 0 : ((charCount - 1) ~/ 400) + 1;
    return _Panel(
      child: Form(
        key: formKey,
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
            const SizedBox(height: 4),
            Text(
              '录入制度、办事说明、FAQ 或内部运维资料，提交后会自动切片并创建向量任务。',
              style: themeData.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final template in _ragTemplates)
                  ActionChip(
                    avatar: Icon(template.icon, size: 16),
                    label: Text(template.label),
                    onPressed: saving ? null : () => _applyTemplate(template),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _UploadBox(
              selectedFile: selectedUploadFile,
              uploading: uploading,
              onPick: saving || uploading ? null : _selectUploadFile,
              onUpload: saving || uploading ? null : _uploadSelectedFile,
              onClear: saving || uploading
                  ? null
                  : () => setState(() => selectedUploadFile = null),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: titleController,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? '请填写资料标题' : null,
              decoration: const InputDecoration(
                labelText: '资料标题',
                hintText: '例如：驾驶员罚款缴纳常见问题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: contentController,
              minLines: 9,
              maxLines: 16,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return '请填写资料正文';
                if (text.length < 20) return '正文过短，建议补充完整上下文';
                return null;
              },
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: '资料正文',
                hintText: '建议按“适用范围 / 办理条件 / 操作步骤 / 注意事项”组织内容。',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.text_fields_rounded,
                  label: '$charCount 字',
                ),
                _InfoChip(
                  icon: Icons.segment_rounded,
                  label: '预计 $estimatedChunks 段',
                ),
                _InfoChip(
                  icon: Icons.security_rounded,
                  label: selectedAclScope,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: sourceIdController,
                    decoration: const InputDecoration(
                      labelText: '来源编号',
                      hintText: '留空自动生成',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: sourceVersionController,
                    decoration: const InputDecoration(
                      labelText: '版本',
                      hintText: '留空自动使用时间戳',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: ValueKey(selectedAclScope),
              initialValue: selectedAclScope,
              decoration: const InputDecoration(
                labelText: '可检索范围',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'PUBLIC', child: Text('PUBLIC 全员')),
                DropdownMenuItem(value: 'USER', child: Text('USER 驾驶员端')),
                DropdownMenuItem(value: 'ROLE', child: Text('ROLE 管理端')),
                DropdownMenuItem(
                  value: 'DEPARTMENT',
                  child: Text('DEPARTMENT 内部部门'),
                ),
              ],
              onChanged: saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => selectedAclScope = value);
                    },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: routeController,
              decoration: const InputDecoration(
                labelText: '关联页面路由',
                hintText: '例如 /fineInformation 或 /admin/logManagement',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: '分类',
                hintText: '例如 罚款缴纳、申诉审批、系统运维',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: tagsController,
              decoration: const InputDecoration(
                labelText: '标签',
                hintText: '用逗号、空格或分号分隔',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: sourceUrlController,
              decoration: const InputDecoration(
                labelText: '来源链接',
                hintText: '可选，政策原文或内部文档地址',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: metadataController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: '额外元数据 JSON',
                hintText: '{"owner":"traffic-admin","priority":"high"}',
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
                  onPressed: saving ? null : _clearForm,
                  tooltip: '清空录入',
                  icon: const Icon(Icons.cleaning_services_rounded),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: saving ? null : _runBackfill,
                  tooltip: '回填业务资料',
                  icon: const Icon(Icons.sync_rounded),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: saving ? null : _runEmbedding,
                  tooltip: '跑一批向量',
                  icon: const Icon(Icons.memory_rounded),
                ),
              ],
            ),
          ],
        ),
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
                  onSubmitted: (_) {
                    setState(() => page = 1);
                    _load();
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: '搜索标题、来源、标签、路由或权限范围',
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
          _buildPreviewPanel(themeData),
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
                onOpen: saving ? null : () => _openDocument(document),
                onDelete: saving ? null : () => _deleteDocument(document),
              ),
            ),
          if (documentTotal > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: page <= 1 || loading
                      ? null
                      : () {
                          setState(() => page = page - 1);
                          _load();
                        },
                  child: const Text('上一页'),
                ),
                Expanded(
                  child: Text(
                    '第 $page / ${((documentTotal + pageSize - 1) / pageSize).ceil()} 页 · 共 $documentTotal 篇',
                    textAlign: TextAlign.center,
                  ),
                ),
                TextButton(
                  onPressed: page >= ((documentTotal + pageSize - 1) / pageSize).ceil() || loading
                      ? null
                      : () {
                          setState(() => page = page + 1);
                          _load();
                        },
                  child: const Text('下一页'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewPanel(ThemeData themeData) {
    final scheme = themeData.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('试检索', style: themeData.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final role in const ['USER', 'ADMIN', 'SUPER_ADMIN'])
              ChoiceChip(
                label: Text(role),
                selected: previewRole == role,
                onSelected: (_) => setState(() => previewRole = role),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: previewQueryController,
                onSubmitted: (_) => _runPreview(),
                decoration: const InputDecoration(
                  hintText: '输入问题，验证不同角色能命中哪些资料',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: previewing ? null : _runPreview,
              child: Text(previewing ? '检索中' : '试检索'),
            ),
          ],
        ),
        if (previewHits.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...previewHits.map(
            (hit) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${hit.score.toStringAsFixed(2)} · ${hit.aclScope} · ${hit.title}\n${hit.snippet}',
                style: themeData.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ],
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.38),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
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

class _UploadBox extends StatelessWidget {
  const _UploadBox({
    required this.selectedFile,
    required this.uploading,
    required this.onPick,
    required this.onUpload,
    required this.onClear,
  });

  final PickedRagFile? selectedFile;
  final bool uploading;
  final VoidCallback? onPick;
  final VoidCallback? onUpload;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final file = selectedFile;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.upload_file_rounded,
                  color: scheme.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '上传文档或表格',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      '支持 txt、md、csv、tsv、json、docx、xlsx、pdf，上传后自动解析为 RAG 文本。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.32,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (file != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.66),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.description_outlined,
                      size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${file.name} · ${file.sizeLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClear,
                    tooltip: '移除文件',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPick,
                  icon: const Icon(Icons.folder_open_rounded),
                  label: Text(file == null ? '选择文件' : '重新选择'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: file == null ? null : onUpload,
                  icon: uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(uploading ? '上传中' : '上传并切片'),
                ),
              ),
            ],
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
    this.onOpen,
  });

  final RagDocumentDto document;
  final VoidCallback? onDelete;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final metadata = _parseMetadata(document.metadataJson);
    final tags = (metadata['tags'] is List)
        ? (metadata['tags'] as List).map((tag) => tag.toString()).toList()
        : const <String>[];
    final category = metadata['category']?.toString() ?? '';
    return InkWell(
      onTap: onOpen,
      child: Container(
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(label: document.status),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _DocumentMetaChip(label: document.sourceType),
                    _DocumentMetaChip(label: document.aclScope),
                    if (category.isNotEmpty) _DocumentMetaChip(label: category),
                    if (document.route.isNotEmpty)
                      _DocumentMetaChip(label: document.route),
                    for (final tag in tags.take(4))
                      _DocumentMetaChip(label: tag),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${document.sourceId} · ${document.sourceVersion} · 更新 ${_formatTime(document.updatedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
                ),
                if (document.contentHash.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Hash ${_shortHash(document.contentHash)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.74),
                      letterSpacing: 0,
                    ),
                  ),
                ],
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
    ),
    );
  }

  Map<String, dynamic> _parseMetadata(String value) {
    if (value.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  String _formatTime(String value) {
    if (value.trim().isEmpty || value == 'null') return '未知';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  String _shortHash(String value) {
    if (value.length <= 10) return value;
    return value.substring(0, 10);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = label.toUpperCase();
    final color = normalized == 'READY'
        ? scheme.primary
        : normalized == 'FAILED'
            ? scheme.error
            : scheme.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.isEmpty ? 'UNKNOWN' : label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
      ),
    );
  }
}

class _DocumentMetaChip extends StatelessWidget {
  const _DocumentMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
      ),
    );
  }
}

class _RagTemplate {
  const _RagTemplate({
    required this.label,
    required this.icon,
    required this.title,
    required this.content,
    required this.category,
    required this.tags,
    required this.route,
    required this.aclScope,
  });

  final String label;
  final IconData icon;
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final String route;
  final String aclScope;
}

const _ragTemplates = [
  _RagTemplate(
    label: '驾驶员 FAQ',
    icon: Icons.help_outline_rounded,
    title: '驾驶员业务办理常见问题',
    category: '驾驶员服务',
    tags: ['违法查询', '罚款缴纳', '用户申诉'],
    route: '/businessProgress',
    aclScope: 'USER',
    content: '''
适用范围：
驾驶员查询个人违法记录、缴纳罚款、提交申诉和查看处理进度。

办理要点：
1. 办理前确认账号已关联司机档案，并完善身份证号、驾驶证号和联系电话。
2. 违法详情用于查看违法时间、地点、违法类型、处理状态和关联车辆信息。
3. 罚款缴纳需先核对罚款记录和金额，支付完成后等待状态同步。
4. 用户申诉应说明申诉原因，并补充证据说明、联系方式和关联违法记录。

注意事项：
若页面提示账号未关联司机档案，请先进入个人资料补全身份和驾驶证信息。
''',
  ),
  _RagTemplate(
    label: '管理员流程',
    icon: Icons.admin_panel_settings_outlined,
    title: '普通管理员业务处理流程',
    category: '管理端业务',
    tags: ['申诉审批', '违法管理', '扣分管理', '罚款管理'],
    route: '/managerBusinessProcessing',
    aclScope: 'ROLE',
    content: '''
适用范围：
普通管理员处理违法行为、申诉审批、扣分记录、罚款记录、司机档案和车辆档案。

处理原则：
1. 先确认用户、司机、车辆和违法记录之间的关联关系。
2. 审批申诉时核对申诉材料、违法记录、证据说明和处理进度。
3. 罚款和扣分处理应保持处理人、处理时间和业务状态一致。
4. 不得绕过权限处理超级管理员专属的日志审查和 RAG 资料管理。

异常处理：
遇到 Forbidden 或无权限提示时，先检查当前账号角色和业务接口权限配置。
''',
  ),
  _RagTemplate(
    label: '运维资料',
    icon: Icons.manage_search_rounded,
    title: '超级管理员系统治理与日志审查说明',
    category: '系统治理',
    tags: ['日志审查', 'RAG 管理', '异常链路'],
    route: '/admin/systemGovernance',
    aclScope: 'ROLE',
    content: '''
适用范围：
超级管理员审查登录日志、操作日志、系统日志，维护 RAG 知识资料，并定位异常链路。

审查重点：
1. 登录日志用于定位异常登录、失败登录和账号风险。
2. 操作日志用于追踪关键业务处理人、处理时间和请求链路。
3. 系统日志用于查看服务异常、接口错误和第三方依赖状态。
4. RAG 资料录入应提供标题、正文、分类、标签和可检索范围。

录入要求：
资料正文应具备明确适用范围、处理步骤和异常处理建议，避免只录入短句。
''',
  ),
];


class _DocumentDetailSheet extends StatefulWidget {
  const _DocumentDetailSheet({required this.detail, required this.onSave});

  final RagDocumentDetail detail;
  final Future<void> Function(String title, String content, String acl, String route) onSave;

  @override
  State<_DocumentDetailSheet> createState() => _DocumentDetailSheetState();
}

class _DocumentDetailSheetState extends State<_DocumentDetailSheet> {
  late final TextEditingController titleController;
  late final TextEditingController contentController;
  late final TextEditingController routeController;
  late String aclScope;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.detail.document.title);
    contentController = TextEditingController(text: widget.detail.content);
    routeController = TextEditingController(text: widget.detail.document.route);
    aclScope = widget.detail.document.aclScope.isEmpty
        ? 'PUBLIC'
        : widget.detail.document.aclScope;
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    routeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final failed = widget.detail.chunks.where((chunk) => chunk.failed).length;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('资料详情', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('切片 ${widget.detail.chunks.length} · 失败 $failed'),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '标题', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: aclScope,
              items: const [
                DropdownMenuItem(value: 'PUBLIC', child: Text('PUBLIC')),
                DropdownMenuItem(value: 'USER', child: Text('USER')),
                DropdownMenuItem(value: 'ROLE', child: Text('ROLE')),
                DropdownMenuItem(value: 'DEPARTMENT', child: Text('DEPARTMENT')),
              ],
              onChanged: (value) => setState(() => aclScope = value ?? 'PUBLIC'),
              decoration: const InputDecoration(labelText: 'ACL', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: routeController,
              decoration: const InputDecoration(labelText: '路由', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contentController,
              minLines: 8,
              maxLines: 16,
              decoration: const InputDecoration(labelText: '正文', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ...widget.detail.chunks.map(
              (chunk) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '#${chunk.chunkNo} ${chunk.embeddingStatus.isEmpty ? chunk.status : chunk.embeddingStatus}${chunk.failed ? " · 失败" : ""}\n${chunk.content}',
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setState(() => saving = true);
                      try {
                        await widget.onSave(
                          titleController.text.trim(),
                          contentController.text.trim(),
                          aclScope,
                          routeController.text.trim(),
                        );
                      } finally {
                        if (mounted) setState(() => saving = false);
                      }
                    },
              child: Text(saving ? '保存中' : '保存并重索引'),
            ),
          ],
        ),
      ),
    );
  }
}
