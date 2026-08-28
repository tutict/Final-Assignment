/**
 * RAG 知识资料管理页（仅 SUPER_ADMIN），对齐 Flutter RagManagementPage。
 * 功能：概览统计、文档列表（搜索 + 删除）、手动录入、文件上传、回填/向量/索引维护按钮。
 */
import { useEffect, useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import PageLayout from "../../components/PageLayout";
import ErrorStateView from "../../components/ErrorStateView";
import { getErrorMessage } from "../../utils/errorMessages";
import {
  createManualRagDocument,
  deleteRagDocument,
  getRagOverview,
  listRagDocuments,
  migrateRagIndex,
  requeueRagEmbeddingTasks,
  runRagBackfill,
  runRagEmbeddingBatch,
  uploadRagDocument,
  type RagDocument,
  type RagOverview,
} from "../../api/rag";

const ACL_SCOPES = ["PUBLIC", "USER", "ROLE", "DEPARTMENT"] as const;
type AclScope = (typeof ACL_SCOPES)[number];

interface RagTemplate {
  label: string;
  title: string;
  content: string;
  category: string;
  tags: string;
  route: string;
  aclScope: AclScope;
}

const RAG_TEMPLATES: RagTemplate[] = [
  {
    label: "驾驶员 FAQ",
    title: "驾驶员业务办理常见问题",
    category: "驾驶员服务",
    tags: "违法查询,罚款缴纳,用户申诉",
    route: "/businessProgress",
    aclScope: "USER",
    content:
      "适用范围：\n驾驶员查询个人违法记录、缴纳罚款、提交申诉和查看处理进度。\n\n办理要点：\n1. 办理前确认账号已关联司机档案，并完善身份证号、驾驶证号和联系电话。\n2. 违法详情用于查看违法时间、地点、违法类型、处理状态和关联车辆信息。\n3. 罚款缴纳需先核对罚款记录和金额，支付完成后等待状态同步。\n4. 用户申诉应说明申诉原因，并补充证据说明、联系方式和关联违法记录。\n\n注意事项：\n若页面提示账号未关联司机档案，请先进入个人资料补全身份和驾驶证信息。",
  },
  {
    label: "管理员流程",
    title: "普通管理员业务处理流程",
    category: "管理端业务",
    tags: "申诉审批,违法管理,扣分管理,罚款管理",
    route: "/managerBusinessProcessing",
    aclScope: "ROLE",
    content:
      "适用范围：\n普通管理员处理违法行为、申诉审批、扣分记录、罚款记录、司机档案和车辆档案。\n\n处理原则：\n1. 先确认用户、司机、车辆和违法记录之间的关联关系。\n2. 审批申诉时核对申诉材料、违法记录、证据说明和处理进度。\n3. 罚款和扣分处理应保持处理人、处理时间和业务状态一致。\n4. 不得绕过权限处理超级管理员专属的日志审查和 RAG 资料管理。\n\n异常处理：\n遇到 Forbidden 或无权限提示时，先检查当前账号角色和业务接口权限配置。",
  },
  {
    label: "运维资料",
    title: "超级管理员系统治理与日志审查说明",
    category: "系统治理",
    tags: "日志审查,RAG 管理,异常链路",
    route: "/admin/systemLogPage",
    aclScope: "ROLE",
    content:
      "适用范围：\n超级管理员审查登录日志、操作日志、系统日志，维护 RAG 知识资料，并定位异常链路。\n\n审查重点：\n1. 登录日志用于定位异常登录、失败登录和账号风险。\n2. 操作日志用于追踪关键业务处理人、处理时间和请求链路。\n3. 系统日志用于查看服务异常、接口错误和第三方依赖状态。\n4. RAG 资料录入应提供标题、正文、分类、标签和可检索范围。\n\n录入要求：\n资料正文应具备明确适用范围、处理步骤和异常处理建议，避免只录入短句。",
  },
];

interface OverviewMetric {
  label: string;
  value: number;
}

function buildOverviewMetrics(overview: RagOverview | undefined): OverviewMetric[] {
  if (!overview) return [];
  return [
    { label: "资料", value: overview.documentCount },
    { label: "READY", value: overview.readyDocumentCount },
    { label: "切片", value: overview.chunkCount },
    { label: "待向量", value: overview.pendingEmbeddingTaskCount },
    { label: "失败任务", value: overview.failedEmbeddingTaskCount },
  ];
}

function parseMetadata(value: string): Record<string, unknown> {
  if (!value || !value.trim()) return {};
  try {
    const decoded = JSON.parse(value);
    return decoded && typeof decoded === "object" ? (decoded as Record<string, unknown>) : {};
  } catch {
    return {};
  }
}

function formatDate(value: string): string {
  if (!value || value.trim() === "" || value === "null") return "未知";
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return value;
  const m = (parsed.getMonth() + 1).toString().padStart(2, "0");
  const d = parsed.getDate().toString().padStart(2, "0");
  return `${parsed.getFullYear()}-${m}-${d}`;
}

function shortHash(value: string): string {
  return value.length <= 10 ? value : value.slice(0, 10);
}

interface ManualFormState {
  title: string;
  content: string;
  sourceId: string;
  sourceVersion: string;
  route: string;
  category: string;
  tags: string;
  sourceUrl: string;
  metadata: string;
  aclScope: AclScope;
}

const EMPTY_FORM: ManualFormState = {
  title: "",
  content: "",
  sourceId: "",
  sourceVersion: "",
  route: "",
  category: "",
  tags: "",
  sourceUrl: "",
  metadata: "",
  aclScope: "PUBLIC",
};

function buildMetadataJson(form: ManualFormState): string | null {
  const tags = form.tags
    .split(/[,，;；\s]+/)
    .map((tag) => tag.trim())
    .filter((tag) => tag.length > 0);
  const metadata: Record<string, unknown> = {
    ingestMode: "manual",
    category: form.category.trim(),
    tags,
    sourceUrl: form.sourceUrl.trim(),
  };
  Object.keys(metadata).forEach((key) => {
    const value = metadata[key];
    if (value === null) delete metadata[key];
    if (typeof value === "string" && value.trim() === "") delete metadata[key];
    if (Array.isArray(value) && value.length === 0) delete metadata[key];
  });
  const extra = form.metadata.trim();
  if (extra) {
    try {
      const decoded = JSON.parse(extra);
      if (!decoded || typeof decoded !== "object" || Array.isArray(decoded)) {
        return null;
      }
      Object.assign(metadata, decoded);
    } catch {
      return null;
    }
  }
  return JSON.stringify(Object.keys(metadata).length === 0 ? {} : metadata);
}

export default function RagManagementPage() {
  const queryClient = useQueryClient();
  const [form, setForm] = useState<ManualFormState>(EMPTY_FORM);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [search, setSearch] = useState("");
  const [toast, setToast] = useState<{ message: string; isError?: boolean } | null>(null);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  const overviewQuery = useQuery({
    queryKey: ["rag", "overview"],
    queryFn: getRagOverview,
  });

  const documentsQuery = useQuery({
    queryKey: ["rag", "documents", search.trim()],
    queryFn: () => listRagDocuments(search.trim() || undefined),
  });

  const reloadAll = () => {
    void queryClient.invalidateQueries({ queryKey: ["rag"] });
  };

  const manualMutation = useMutation({
    mutationFn: () => {
      const metadataJson = buildMetadataJson(form);
      if (metadataJson === null) {
        throw new Error("额外元数据必须是 JSON 对象");
      }
      return createManualRagDocument({
        title: form.title,
        content: form.content,
        sourceId: form.sourceId,
        sourceVersion: form.sourceVersion,
        aclScope: form.aclScope,
        route: form.route,
        metadataJson,
      });
    },
    onSuccess: (result) => {
      setToast({
        message: `RAG 资料已录入：生成 ${result.chunkCount} 个切片，${result.embeddingTaskCount} 个向量任务`,
      });
      setForm(EMPTY_FORM);
      setFieldErrors({});
      reloadAll();
    },
    onError: (error) => setToast({ message: `录入失败：${getErrorMessage(error)}`, isError: true }),
  });

  const uploadMutation = useMutation({
    mutationFn: () => {
      if (!selectedFile) throw new Error("请先选择文档或表格");
      const metadataJson = buildMetadataJson(form);
      if (metadataJson === null) throw new Error("额外元数据必须是 JSON 对象");
      return uploadRagDocument({
        file: selectedFile,
        sourceId: form.sourceId,
        sourceVersion: form.sourceVersion,
        title: form.title,
        aclScope: form.aclScope,
        route: form.route,
        metadataJson,
      });
    },
    onSuccess: (result) => {
      setToast({
        message: `文件已录入：生成 ${result.chunkCount} 个切片，${result.embeddingTaskCount} 个向量任务`,
      });
      setSelectedFile(null);
      setForm(EMPTY_FORM);
      setFieldErrors({});
      reloadAll();
    },
    onError: (error) => setToast({ message: `上传录入失败：${getErrorMessage(error)}`, isError: true }),
  });

  const deleteMutation = useMutation({
    mutationFn: (documentId: string) => deleteRagDocument(documentId),
    onSuccess: () => {
      setToast({ message: "资料已删除" });
      reloadAll();
    },
    onError: (error) => setToast({ message: `删除失败：${getErrorMessage(error)}`, isError: true }),
  });

  const backfillMutation = useMutation({
    mutationFn: () => runRagBackfill(),
    onSuccess: () => {
      setToast({ message: "已触发一批 RAG 回填" });
      reloadAll();
    },
    onError: (error) => setToast({ message: `回填失败：${getErrorMessage(error)}`, isError: true }),
  });

  const embeddingMutation = useMutation({
    mutationFn: () => runRagEmbeddingBatch(),
    onSuccess: (result) => {
      setToast({
        message: `向量任务已执行：选中 ${result.selectedTasks}，成功 ${result.succeededTasks}，失败 ${result.failedTasks}`,
      });
      reloadAll();
    },
    onError: (error) => setToast({ message: `向量任务失败：${getErrorMessage(error)}`, isError: true }),
  });

  const requeueMutation = useMutation({
    mutationFn: () => requeueRagEmbeddingTasks(),
    onSuccess: (result) => {
      setToast({
        message: `已重新入队：切片 ${result.requeuedChunks}，任务 ${result.requeuedTasks}，新建 ${result.createdTasks}`,
      });
      reloadAll();
    },
    onError: (error) => setToast({ message: `重新入队失败：${getErrorMessage(error)}`, isError: true }),
  });

  const migrateMutation = useMutation({
    mutationFn: () => migrateRagIndex({ requeue: true }),
    onSuccess: (result) => {
      setToast({
        message: result.message || `索引迁移完成：${result.targetIndexName || "未知"}`,
      });
      reloadAll();
    },
    onError: (error) => setToast({ message: `索引迁移失败：${getErrorMessage(error)}`, isError: true }),
  });

  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(null), 4000);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const overview = overviewQuery.data;
  const metrics = useMemo(() => buildOverviewMetrics(overview), [overview]);
  const documents = documentsQuery.data || [];
  const charCount = form.content.length;
  const estimatedChunks = charCount === 0 ? 0 : Math.floor((charCount - 1) / 400) + 1;
  const disabled = manualMutation.isPending || uploadMutation.isPending;
  const ragDisabled = overview ? !overview.ragEnabled || !overview.indexingEnabled : false;

  const applyTemplate = (template: RagTemplate) => {
    setForm((prev) => ({
      ...prev,
      title: template.title,
      content: template.content,
      category: template.category,
      tags: template.tags,
      route: template.route,
      aclScope: template.aclScope,
      sourceVersion: `v${Date.now()}`,
    }));
  };

  const handleSubmit = () => {
    const errors: Record<string, string> = {};
    if (!form.title.trim()) errors.title = "请填写资料标题";
    if (!form.content.trim()) errors.content = "请填写资料正文";
    else if (form.content.trim().length < 20) errors.content = "正文过短，建议补充完整上下文";
    setFieldErrors(errors);
    if (Object.keys(errors).length > 0) return;
    manualMutation.mutate();
  };

  return (
    <PageLayout title="RAG 资料管理" subtitle="录入知识资料 · 触发回填 · 检查索引切片状态">
      {toast ? (
        <div className={toast.isError ? "form-error rag-toast" : "rag-toast rag-toast-success"}>
          {toast.message}
        </div>
      ) : null}

      {overviewQuery.isError ? (
        <ErrorStateView message={getErrorMessage(overviewQuery.error)} onRetry={() => overviewQuery.refetch()} />
      ) : null}

      <div className="rag-overview">
        {overviewQuery.isLoading ? <span className="placeholder">加载中...</span> : null}
        {metrics.map((metric) => (
          <div key={metric.label} className="rag-metric">
            <span className="rag-metric-value">{metric.value}</span>
            <span className="rag-metric-label">{metric.label}</span>
          </div>
        ))}
      </div>

      {ragDisabled && overview ? (
        <div className="form-error" style={{ marginBottom: 16 }}>
          RAG 或索引能力未启用，请检查后端 rag.enabled / rag.indexing.enabled 配置。
        </div>
      ) : null}

      <div className="rag-actions">
        <button type="button" className="ghost" onClick={() => backfillMutation.mutate()} disabled={backfillMutation.isPending}>
          {backfillMutation.isPending ? "回填中..." : "回填业务资料"}
        </button>
        <button type="button" className="ghost" onClick={() => embeddingMutation.mutate()} disabled={embeddingMutation.isPending}>
          {embeddingMutation.isPending ? "执行中..." : "执行向量任务"}
        </button>
        <button type="button" className="ghost" onClick={() => requeueMutation.mutate()} disabled={requeueMutation.isPending}>
          {requeueMutation.isPending ? "入队中..." : "重新入队向量"}
        </button>
        <button type="button" className="ghost" onClick={() => migrateMutation.mutate()} disabled={migrateMutation.isPending}>
          {migrateMutation.isPending ? "迁移中..." : "索引迁移"}
        </button>
      </div>

      <div className="rag-layout">
        <div className="panel rag-form-panel">
          <h3>录入资料</h3>
          <p className="rag-hint">
            录入制度、办事说明、FAQ 或内部运维资料，提交后会自动切片并创建向量任务。
          </p>

          <div className="rag-templates">
            {RAG_TEMPLATES.map((template) => (
              <button
                key={template.label}
                type="button"
                className="chip"
                onClick={() => applyTemplate(template)}
                disabled={disabled}
              >
                {template.label}
              </button>
            ))}
          </div>

          <div className="rag-upload">
            <div className="rag-upload-title">上传文档或表格</div>
            <div className="rag-hint">
              支持 txt、md、csv、tsv、json、docx、xlsx、pdf，上传后自动解析为 RAG 文本。
            </div>
            {selectedFile ? (
              <div className="rag-file-row">
                <span className="rag-file-name">{selectedFile.name} · {(selectedFile.size / 1024).toFixed(1)} KB</span>
                <button type="button" className="link-button danger" onClick={() => setSelectedFile(null)}>
                  移除
                </button>
              </div>
            ) : null}
            <div className="rag-upload-actions">
              <label className="ghost">
                选择文件
                <input
                  type="file"
                  hidden
                  onChange={(event) => {
                    const file = event.target.files?.[0];
                    if (file) {
                      setSelectedFile(file);
                      setForm((prev) => ({
                        ...prev,
                        title: prev.title || file.name,
                        sourceVersion: prev.sourceVersion || `v${Date.now()}`,
                      }));
                    }
                  }}
                />
              </label>
              <button
                type="button"
                className="primary"
                onClick={() => uploadMutation.mutate()}
                disabled={!selectedFile || uploadMutation.isPending}
              >
                {uploadMutation.isPending ? "上传中..." : "上传并切片"}
              </button>
            </div>
          </div>

          <label className="form-field">
            <span>资料标题</span>
            <input
              type="text"
              value={form.title}
              placeholder="例如：驾驶员罚款缴纳常见问题"
              onChange={(event) => setForm((prev) => ({ ...prev, title: event.target.value }))}
            />
            {fieldErrors.title ? <small className="field-error">{fieldErrors.title}</small> : null}
          </label>

          <label className="form-field">
            <span>资料正文</span>
            <textarea
              rows={9}
              value={form.content}
              placeholder="建议按“适用范围 / 办理条件 / 操作步骤 / 注意事项”组织内容。"
              onChange={(event) => setForm((prev) => ({ ...prev, content: event.target.value }))}
            />
            {fieldErrors.content ? <small className="field-error">{fieldErrors.content}</small> : null}
          </label>

          <div className="rag-chips">
            <span className="chip">{charCount} 字</span>
            <span className="chip">预计 {estimatedChunks} 段</span>
            <span className="chip">{form.aclScope}</span>
          </div>

          <div className="rag-row">
            <label className="form-field">
              <span>来源编号</span>
              <input
                type="text"
                value={form.sourceId}
                placeholder="留空自动生成"
                onChange={(event) => setForm((prev) => ({ ...prev, sourceId: event.target.value }))}
              />
            </label>
            <label className="form-field">
              <span>版本</span>
              <input
                type="text"
                value={form.sourceVersion}
                placeholder="留空自动使用时间戳"
                onChange={(event) => setForm((prev) => ({ ...prev, sourceVersion: event.target.value }))}
              />
            </label>
          </div>

          <label className="form-field">
            <span>可检索范围</span>
            <select
              value={form.aclScope}
              onChange={(event) => setForm((prev) => ({ ...prev, aclScope: event.target.value as AclScope }))}
            >
              {ACL_SCOPES.map((scope) => (
                <option key={scope} value={scope}>{scope}</option>
              ))}
            </select>
          </label>

          <label className="form-field">
            <span>关联页面路由</span>
            <input
              type="text"
              value={form.route}
              placeholder="例如 /fineInformation 或 /admin/logManagement"
              onChange={(event) => setForm((prev) => ({ ...prev, route: event.target.value }))}
            />
          </label>

          <label className="form-field">
            <span>分类</span>
            <input
              type="text"
              value={form.category}
              placeholder="例如 罚款缴纳、申诉审批、系统运维"
              onChange={(event) => setForm((prev) => ({ ...prev, category: event.target.value }))}
            />
          </label>

          <label className="form-field">
            <span>标签</span>
            <input
              type="text"
              value={form.tags}
              placeholder="用逗号、空格或分号分隔"
              onChange={(event) => setForm((prev) => ({ ...prev, tags: event.target.value }))}
            />
          </label>

          <label className="form-field">
            <span>来源链接</span>
            <input
              type="text"
              value={form.sourceUrl}
              placeholder="可选，政策原文或内部文档地址"
              onChange={(event) => setForm((prev) => ({ ...prev, sourceUrl: event.target.value }))}
            />
          </label>

          <label className="form-field">
            <span>额外元数据 JSON</span>
            <textarea
              rows={3}
              value={form.metadata}
              placeholder='{"owner":"traffic-admin","priority":"high"}'
              onChange={(event) => setForm((prev) => ({ ...prev, metadata: event.target.value }))}
            />
          </label>

          <div className="rag-submit-row">
            <button type="button" className="primary" onClick={handleSubmit} disabled={disabled}>
              {manualMutation.isPending ? "处理中..." : "录入并切片"}
            </button>
            <button type="button" className="ghost" onClick={() => { setForm(EMPTY_FORM); setFieldErrors({}); }} disabled={disabled}>
              清空录入
            </button>
          </div>
        </div>

        <div className="panel rag-documents-panel">
          <div className="rag-search-row">
            <input
              type="text"
              value={search}
              placeholder="搜索标题、来源、标签、路由或权限范围"
              onChange={(event) => setSearch(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === "Enter") documentsQuery.refetch();
              }}
            />
            <button type="button" className="ghost" onClick={() => documentsQuery.refetch()}>刷新</button>
          </div>

          {documentsQuery.isLoading ? <div className="placeholder">加载中...</div> : null}
          {documentsQuery.isError ? (
            <ErrorStateView message={getErrorMessage(documentsQuery.error)} onRetry={() => documentsQuery.refetch()} />
          ) : null}

          {documents.length === 0 && !documentsQuery.isLoading ? (
            <div className="placeholder">暂无 RAG 资料</div>
          ) : null}

          {documents.map((document) => (
            <DocumentTile
              key={document.id}
              document={document}
              onDelete={() => deleteMutation.mutate(document.id)}
              deleting={deleteMutation.isPending}
            />
          ))}
        </div>
      </div>
    </PageLayout>
  );
}

interface DocumentTileProps {
  document: RagDocument;
  onDelete: () => void;
  deleting: boolean;
}

function DocumentTile({ document, onDelete, deleting }: DocumentTileProps) {
  const metadata = parseMetadata(document.metadataJson);
  const tags = Array.isArray(metadata.tags) ? metadata.tags.map(String) : [];
  const category = metadata.category ? String(metadata.category) : "";
  const normalized = document.status.toUpperCase();
  const statusClass =
    normalized === "READY"
      ? "rag-status-ready"
      : normalized === "FAILED"
        ? "rag-status-failed"
        : "rag-status-other";
  return (
    <div className="rag-doc-tile">
      <div className="rag-doc-main">
        <div className="rag-doc-title-row">
          <span className="rag-doc-title">{document.title || "未命名资料"}</span>
          <span className={`rag-status-badge ${statusClass}`}>{document.status || "UNKNOWN"}</span>
        </div>
        <div className="rag-doc-chips">
          {document.sourceType ? <span className="rag-doc-chip">{document.sourceType}</span> : null}
          {document.aclScope ? <span className="rag-doc-chip">{document.aclScope}</span> : null}
          {category ? <span className="rag-doc-chip">{category}</span> : null}
          {document.route ? <span className="rag-doc-chip">{document.route}</span> : null}
          {tags.slice(0, 4).map((tag) => (
            <span key={tag} className="rag-doc-chip">{tag}</span>
          ))}
        </div>
        <div className="rag-doc-meta">
          {document.sourceId} · {document.sourceVersion} · 更新 {formatDate(document.updatedAt)}
        </div>
        {document.contentHash ? (
          <div className="rag-doc-hash">Hash {shortHash(document.contentHash)}</div>
        ) : null}
      </div>
      <button type="button" className="link-button danger" onClick={onDelete} disabled={deleting}>
        删除
      </button>
    </div>
  );
}
