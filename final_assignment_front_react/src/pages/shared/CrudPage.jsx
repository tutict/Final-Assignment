import React, { useMemo, useState } from 'react';
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

function normalizeFields(config) {
  return config.fields.map((field) => ({
    label: humanizeKey(field.name),
    ...field,
  }));
}

export default function CrudPage({ config }) {
  const [search, setSearch] = useState('');
  const [editing, setEditing] = useState(null);
  const [formData, setFormData] = useState({});
  const [modalOpen, setModalOpen] = useState(false);

  const fields = useMemo(() => normalizeFields(config), [config]);

  const fetchList = config.list
    ? config.list
    : () => listEntities(config.basePath, config.listParams);

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: [config.key],
    queryFn: fetchList,
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
    if (!search.trim()) return rows;
    const query = normalizeText(search);
    return rows.filter((row) =>
      fields.some((field) => normalizeText(row?.[field.name]).includes(query))
    );
  }, [rows, fields, search]);

  const columns = useMemo(() => {
    return fields.slice(0, 8).map((field) => ({
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
  }, [fields]);

  const handleOpenCreate = () => {
    setEditing(null);
    setFormData({});
    setModalOpen(true);
  };

  const handleEdit = (row) => {
    setEditing(row);
    setFormData(row || {});
    setModalOpen(true);
  };

  const handleDelete = async (row) => {
    const id = row?.[config.idField];
    if (!id) return;
    if (window.confirm('确定删除该记录吗？')) {
      await deleteMutation.mutateAsync(id);
    }
  };

  const handleSave = async () => {
    const editableFields = fields.filter((field) => !field.readOnly).map((field) => field.name);
    const basePayload = editableFields.reduce((acc, key) => {
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

  return (
    <PageLayout
      title={config.label}
      subtitle={config.subtitle || '数据管理与业务操作'}
      actions={
        <button type="button" className="primary" onClick={handleOpenCreate}>
          新增
        </button>
      }
    >
      <SearchBar value={search} onChange={setSearch} placeholder={`搜索${config.label}...`} />
      {isLoading ? <div className="placeholder">加载中...</div> : null}
      {error ? <div className="form-error">加载失败，请检查后端服务。</div> : null}
      <DataTable
        columns={columns}
        rows={filteredRows}
        onEdit={handleEdit}
        onDelete={handleDelete}
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
          fields={fields}
          value={formData}
          onChange={(name, value) => setFormData((prev) => ({ ...prev, [name]: value }))}
          disabledFields={[config.idField]}
        />
      </Modal>
    </PageLayout>
  );
}
