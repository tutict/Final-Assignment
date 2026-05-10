import React, { useDeferredValue, useMemo, useState } from 'react';
import { useMutation, useQuery } from '@tanstack/react-query';
import PageLayout from '../../components/PageLayout.jsx';
import DataTable from '../../components/DataTable.jsx';
import SearchBar from '../../components/SearchBar.jsx';
import Modal from '../../components/Modal.jsx';
import EntityForm from '../../components/EntityForm.jsx';
import StatusPill from '../../components/StatusPill.jsx';
import {
  createEntity,
  deleteEntity,
  listEntities,
  updateEntity,
} from '../../api/entities.js';
import { formatDateTime, humanizeKey, normalizeText } from '../../utils/format.js';

function normalizeFields(config, allowedNames) {
  const fields = config.fields || [];
  const fieldMap = new Map(fields.map((field) => [field.name, field]));
  const names = allowedNames || fields.map((field) => field.name);

  return names
    .map((name) => fieldMap.get(name))
    .filter(Boolean)
    .map((field) => ({
      label: humanizeKey(field.name),
      ...field,
    }));
}

export default function CrudPage({ config }) {
  const [search, setSearch] = useState('');
  const [editing, setEditing] = useState(null);
  const [formData, setFormData] = useState({});
  const [modalOpen, setModalOpen] = useState(false);
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

  const fetchList = config.list
    ? config.list
    : () => listEntities(config.basePath, config.listParams);

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: [config.key],
    queryFn: fetchList,
    enabled: !useCustomPage,
  });

  const createMutation = useMutation({
    mutationFn: (payload) => createEntity(config.basePath, payload),
    onSuccess: () => refetch(),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }) => updateEntity(config.basePath, id, payload),
    onSuccess: () => refetch(),
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => deleteEntity(config.basePath, id),
    onSuccess: () => refetch(),
  });

  const rows = Array.isArray(data) ? data : [];

  const filteredRows = useMemo(() => {
    if (!deferredSearch.trim()) return rows;
    const query = normalizeText(deferredSearch);
    return rows.filter((row) =>
      displayFields.some((field) => normalizeText(row?.[field.name]).includes(query))
    );
  }, [rows, displayFields, deferredSearch]);

  const columns = useMemo(() => {
    return displayFields.map((field) => ({
      key: field.name,
      label: field.label,
      render: (row) => {
        const value = row?.[field.name];
        if (field.type === 'DateTime') {
          return formatDateTime(value);
        }
        if (field.name.toLowerCase().includes('status')) {
          return <StatusPill value={value} />;
        }
        return value ?? '';
      },
    }));
  }, [displayFields]);

  const handleOpenCreate = () => {
    if (!canMutate) return;
    setEditing(null);
    setFormData({});
    setModalOpen(true);
  };

  const handleEdit = (row) => {
    if (!canMutate) return;
    setEditing(row);
    setFormData(row || {});
    setModalOpen(true);
  };

  const handleDelete = async (row) => {
    if (!canMutate) return;
    const id = row?.[config.idField];
    if (!id) return;
    if (window.confirm('确定删除该记录吗？')) {
      await deleteMutation.mutateAsync(id);
    }
  };

  const handleSave = async () => {
    if (!canMutate) return;
    const editableFieldNames = editableFields.map((field) => field.name);
    const basePayload = editableFieldNames.reduce((acc, key) => {
      acc[key] = formData[key];
      return acc;
    }, {});
    const payload = config.preparePayload ? config.preparePayload(basePayload) : basePayload;
    if (editing) {
      const id = editing?.[config.idField];
      if (!id) return;
      await updateMutation.mutateAsync({ id, payload });
    } else {
      await createMutation.mutateAsync(payload);
    }
    setModalOpen(false);
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
      actions={
        canMutate ? (
          <button type="button" className="primary" onClick={handleOpenCreate}>
            新增
          </button>
        ) : null
      }
    >
      {!canMutate ? <div className="placeholder">此实体为只读视图</div> : null}
      <SearchBar
        value={search}
        onChange={setSearch}
        placeholder={`搜索${config.label}...`}
        actions={search !== deferredSearch ? <span className="search-hint">筛选中...</span> : null}
      />
      {isLoading ? <div className="placeholder">加载中...</div> : null}
      {error ? <div className="form-error">加载失败，请检查后端服务。</div> : null}
      <DataTable
        columns={columns}
        rows={filteredRows}
        onEdit={canMutate ? handleEdit : undefined}
        onDelete={canMutate ? handleDelete : undefined}
      />
      <Modal
        open={modalOpen}
        title={editing ? `编辑${config.label}` : `新增${config.label}`}
        onClose={() => setModalOpen(false)}
        footer={
          <div className="modal-actions">
            <button type="button" className="ghost" onClick={() => setModalOpen(false)}>
              取消
            </button>
            <button type="button" className="primary" onClick={handleSave}>
              保存
            </button>
          </div>
        }
        wide
      >
        <EntityForm
          fields={editableFields}
          value={formData}
          onChange={(name, value) => setFormData((prev) => ({ ...prev, [name]: value }))}
          disabledFields={[config.idField]}
        />
      </Modal>
    </PageLayout>
  );
}
