import { useDeferredValue, useEffect, useMemo, useState } from 'react';
import { useMutation, useQuery, type UseQueryResult } from '@tanstack/react-query';
import PageLayout from '../../components/PageLayout';
import DataTable from '../../components/DataTable';
import SearchBar from '../../components/SearchBar';
import Modal from '../../components/Modal';
import EntityForm, { validateEntityForm } from '../../components/EntityForm';
import { useConfirm } from '../../hooks/useConfirm';
import { useModalState } from '../../hooks/useModalState';
import {
  createEntity,
  deleteEntity,
  listEntities,
  updateEntity,
} from '../../api/entities';
import { buildColumns } from '../../utils/buildColumns';
import { getErrorMessage } from '../../utils/errorMessages';
import { normalizeText } from '../../utils/format';
import { resolveFieldLabel } from '../../config/fieldLabels';
import type { EntityConfig, EntityField } from '../../config/entityTypes';

type NormalizedField = EntityField & { label: string };

function normalizeFields(
  config: EntityConfig,
  allowedNames?: string[]
): NormalizedField[] {
  const fields = config.fields || [];
  const fieldMap = new Map(fields.map((field) => [field.name, field]));
  const names = allowedNames || fields.map((field) => field.name);

  return names
    .map((name) => fieldMap.get(name))
    .filter((field): field is EntityField => Boolean(field))
    .map((field) => ({ ...field, label: resolveFieldLabel(field.name, field.label) })) as NormalizedField[];
}

interface CrudPageProps {
  config: EntityConfig;
}

export default function CrudPage({ config }: CrudPageProps) {
  const [search, setSearch] = useState('');
  const [viewing, setViewing] = useState<Record<string, unknown> | null>(null);
  const [formData, setFormData] = useState<Record<string, unknown>>({});
  const [formError, setFormError] = useState('');
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const {
    isOpen: isModalOpen,
    activeRow: editing,
    open,
    close,
  } = useModalState();
  const deferredSearch = useDeferredValue(search);

  const allFields = useMemo(() => normalizeFields(config), [config]);
  const displayFields = useMemo(
    () => normalizeFields(config, config.displayFields),
    [config]
  );
  const editableFields = useMemo(() => {
    const fields = config.editableFields
      ? normalizeFields(config, config.editableFields)
      : allFields.filter((field) => !field.readOnly);
    return fields.filter((field) => !field.readOnly);
  }, [allFields, config]);
  const useCustomPage = Boolean(config.useCustomPage);
  const canMutate = !useCustomPage && editableFields.length > 0;
  const cards = config.layout === 'cards';
  const showCreate = canMutate && !config.hideCreate;

  const fetchList = config.list
    ? config.list
    : () => listEntities(config.basePath, config.listParams);

  const internalQuery = useQuery({
    queryKey: [config.key],
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    queryFn: fetchList as any,
    enabled: !useCustomPage && !config.queryResult,
  });
  const queryResult = (config.queryResult || internalQuery) as UseQueryResult<
    Record<string, unknown>[],
    unknown
  > & { refetch?: () => void };
  const { data, isLoading, error, refetch = () => {} } = queryResult;

  const createMutation = useMutation({
    mutationFn: (payload: unknown) => createEntity(config.basePath, payload),
    onSuccess: () => refetch(),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string | number; payload: unknown }) =>
      updateEntity(config.basePath, id, payload),
    onSuccess: () => refetch(),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string | number) => deleteEntity(config.basePath, id),
    onSuccess: () => refetch(),
  });

  const rows: Record<string, unknown>[] = Array.isArray(data) ? data : [];

  const filteredRows = useMemo(() => {
    if (!deferredSearch.trim()) return rows;
    const query = normalizeText(deferredSearch);
    return rows.filter((row) =>
      config.errorRowMessage?.(row) ||
      displayFields.some((field) => normalizeText(row?.[field.name]).includes(query))
    );
  }, [rows, displayFields, deferredSearch, config]);

  const columns = useMemo(() => buildColumns(displayFields), [displayFields]);
  const pageSize = 20;
  const [page, setPage] = useState(1);
  const pageCount = Math.max(1, Math.ceil(filteredRows.length / pageSize));
  const currentPage = Math.min(page, pageCount);

  useEffect(() => {
    setPage(1);
  }, [deferredSearch]);

  useEffect(() => {
    if (page > pageCount) setPage(pageCount);
  }, [page, pageCount]);

  const pagedRows = filteredRows.slice((currentPage - 1) * pageSize, currentPage * pageSize);

  const handleOpenCreate = () => {
    if (!canMutate) return;
    setFormError('');
    setFieldErrors({});
    setFormData({});
    open();
  };

  const handleEdit = (row: Record<string, unknown>) => {
    if (!canMutate) return;
    setFormError('');
    setFieldErrors({});
    setFormData(row || {});
    open(row);
  };

  const handleCloseModal = () => {
    setFormError('');
    setFieldErrors({});
    close();
  };

  const { confirm: handleConfirmDelete, loading: deleteLoading } = useConfirm(
    async (...args: unknown[]) => {
      if (!canMutate) return;
      const row = args[0] as Record<string, unknown>;
      const id = row?.[config.idField] as string | number | undefined;
      if (!id) return;
      if (window.confirm('确定删除该记录吗？')) {
        await deleteMutation.mutateAsync(id);
      }
    },
    {
      onSuccess: handleCloseModal,
      onError: (error) => {
        setFormError(getErrorMessage(error));
      },
    }
  );

  const { confirm: handleConfirmSave, loading: saveLoading } = useConfirm(
    async () => {
      if (!canMutate) return;
      setFormError('');
      const editableFieldNames = editableFields.map((field) => field.name);
      const basePayload = editableFieldNames.reduce<Record<string, unknown>>(
        (acc, key) => {
          acc[key] = formData[key];
          return acc;
        },
        {}
      );
      const payload = config.preparePayload
        ? config.preparePayload(basePayload)
        : basePayload;
      if (editing) {
        const id = editing?.[config.idField] as string | number | undefined;
        if (!id) return;
        await updateMutation.mutateAsync({ id, payload });
      } else {
        await createMutation.mutateAsync(payload);
      }
    },
    {
      onSuccess: handleCloseModal,
      onError: (error) => {
        setFormError(getErrorMessage(error));
      },
    }
  );

  const handleSaveClick = () => {
    const errors = validateEntityForm(editableFields, formData);
    if (Object.keys(errors).length > 0) {
      setFormError('');
      setFieldErrors(errors);
      return;
    }

    setFieldErrors({});
    handleConfirmSave();
  };

  if (useCustomPage) {
    return (
      <PageLayout
        title={config.label}
        subtitle={config.subtitle || '此实体需使用专属业务页面管理'}
      >
        <div className="placeholder">此实体需使用专属业务页面管理</div>
      </PageLayout>
    );
  }

  return (
    <PageLayout
      title={config.label}
      subtitle={config.subtitle || '数据管理与业务操作'}
      headerActions={
        showCreate ? (
          <button type="button" className="primary" onClick={handleOpenCreate}>
            新增
          </button>
        ) : null
      }
    >
      {!canMutate && !cards ? <div className="placeholder">此实体为只读视图</div> : null}
      <SearchBar
        value={search}
        onChange={setSearch}
        placeholder={`搜索${config.label}...`}
        actions={search !== deferredSearch ? <span className="search-hint">筛选中...</span> : null}
      />
      {deferredSearch.trim() ? (
        <div className="page-actions">
          <span className="filter-chip">
            筛选：{deferredSearch.trim()}
            <button type="button" className="link-button" onClick={() => setSearch('')}>
              清除
            </button>
          </span>
        </div>
      ) : null}
      {isLoading ? <div className="placeholder">正在加载，请稍候。</div> : null}
      {error ? (
        <div className="error-state">
          <p>列表没有加载成功。已填写的搜索会保留，可以重试。</p>
          <button type="button" className="ghost" onClick={() => refetch()}>重试</button>
        </div>
      ) : null}
      {!isLoading && !error && cards ? (
        pagedRows.length === 0 ? null : (
          <div className="record-list">
            {pagedRows.map((row) => {
              const titleField = displayFields[0];
              const title = titleField ? String(row[titleField.name] ?? '未命名记录') : '未命名记录';
              const key = String(row[config.idField] ?? title);
              return (
                <button
                  key={key}
                  type="button"
                  className="task-card"
                  onClick={() => {
                    config.onView?.(row);
                    setViewing(row);
                  }}
                >
                  <strong>{title}</strong>
                  {displayFields.slice(1, 4).map((field) => (
                    <span key={field.name}>
                      {field.label}：{String(row[field.name] ?? '—')}
                    </span>
                  ))}
                </button>
              );
            })}
          </div>
        )
      ) : null}
      {!isLoading && !error && !cards ? (
      <DataTable
        columns={columns}
        rows={pagedRows}
        onEdit={canMutate ? handleEdit : undefined}
        onDelete={canMutate ? handleConfirmDelete : undefined}
        onView={config.onView}
        onRowClick={setViewing}
        emptyMessage={deferredSearch.trim() ? '没有符合筛选的记录。清除筛选后再看，或新增一条。' : (showCreate ? '暂无记录。可以使用页面上的主操作新增。' : '暂无记录。')}
        getRowErrorMessage={config.errorRowMessage}
      />
      ) : null}
      {cards && !isLoading && !error && pagedRows.length === 0 ? (
        <div className="placeholder">
          {deferredSearch.trim() ? '没有符合筛选的记录。清除筛选后再看。' : (showCreate ? '暂无记录。可以使用页面上的主操作新增。' : '暂无记录。')}
        </div>
      ) : null}
      {filteredRows.length > 0 ? (
        <div className="table-pager">
          <span>第 {currentPage} / {pageCount} 页</span>
          <button type="button" className="ghost" disabled={currentPage <= 1} onClick={() => setPage(currentPage - 1)}>
            上一页
          </button>
          <button type="button" className="ghost" disabled={currentPage >= pageCount} onClick={() => setPage(currentPage + 1)}>
            下一页
          </button>
        </div>
      ) : null}
      {viewing ? (
        <aside className="detail-drawer" aria-label="记录详情">
          <h2>记录详情</h2>
          {displayFields.map((field) => (
            <p key={field.name}>
              <strong>{field.label}：</strong>
              {String(viewing[field.name] ?? '—')}
            </p>
          ))}
          <button type="button" className="ghost" onClick={() => setViewing(null)}>关闭</button>
        </aside>
      ) : null}
      <Modal
        isOpen={isModalOpen}
        title={editing ? `编辑${config.label}` : `新增${config.label}`}
        onClose={handleCloseModal}
        footerActions={
          <div className="modal-actions">
            <button type="button" className="ghost" onClick={handleCloseModal}>
              取消
            </button>
            <button
              type="button"
              className="primary"
              onClick={handleSaveClick}
              disabled={saveLoading || deleteLoading}
            >
              保存
            </button>
          </div>
        }
        wide
      >
        {formError ? <div className="form-error">{formError}</div> : null}
        <EntityForm
          fields={editableFields}
          value={formData}
          onChange={(name, value) => {
            if (formError) setFormError('');
            if (fieldErrors[name]) {
              setFieldErrors((prev) => {
                const next = { ...prev };
                delete next[name];
                return next;
              });
            }
            setFormData((prev) => ({ ...prev, [name]: value }));
          }}
          disabledFields={[config.idField]}
          fieldErrors={fieldErrors}
        />
      </Modal>
    </PageLayout>
  );
}
