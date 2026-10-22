/**
 * 用户管理页，对齐 Flutter UserManagementPage。
 * 检索维度：按账号 / 按姓名 / 按状态 / 按部门 / 按联系电话 / 按邮箱。
 * 其中账号、姓名、状态、部门、联系电话走服务端检索端点，邮箱按 Flutter 行为做客户端过滤。
 */
import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import PageLayout from '../../components/PageLayout';
import DataTable from '../../components/DataTable';
import SearchFilterBar, { type SearchTypeOption } from '../../components/SearchFilterBar';
import Modal from '../../components/Modal';
import EntityForm, { validateEntityForm } from '../../components/EntityForm';
import ErrorStateView from '../../components/ErrorStateView';
import { useConfirm } from '../../hooks/useConfirm';
import { useModalState } from '../../hooks/useModalState';
import { buildColumns } from '../../utils/buildColumns';
import { getErrorMessage } from '../../utils/errorMessages';
import { formatDate } from '../../utils/format';
import type { EntityField } from '../../config/entityTypes';
import {
  createUser,
  deleteUser,
  listUsers,
  searchUsersByContact,
  searchUsersByDepartment,
  searchUsersByRealNamePrefix,
  searchUsersByStatus,
  searchUsersByUsernamePrefix,
  updateUser,
  type ManagedUser,
} from '../../api/users';

const SEARCH_OPTIONS: SearchTypeOption[] = [
  { value: 'username', label: '按账号', hint: '账号前缀匹配' },
  { value: 'real-name', label: '按姓名', hint: '姓名前缀匹配' },
  { value: 'status', label: '按状态', hint: '例如 Active / Inactive' },
  { value: 'department', label: '按部门', hint: '部门名称匹配' },
  { value: 'contact', label: '按联系电话', hint: '联系电话匹配' },
  { value: 'email', label: '按邮箱', hint: '邮箱包含匹配（本地过滤）' },
];

const STATUS_OPTIONS = ['Active', 'Inactive'] as const;
const GENDER_OPTIONS = ['Male', 'Female', 'Other'] as const;

const FORM_FIELDS: EntityField[] = [
  {
    name: 'username',
    type: 'String',
    label: '账号',
    validation: {
      required: true,
      minLength: 3,
      maxLength: 50,
      message: '账号长度须为 3~50 个字符',
    },
  },
  {
    name: 'password',
    type: 'String',
    label: '密码（新增必填，编辑留空不改）',
    validation: { minLength: 8, maxLength: 100, message: '密码长度须为 8~100 位' },
  },
  { name: 'realName', type: 'String', label: '姓名' },
  {
    name: 'gender',
    type: 'select',
    label: '性别',
    options: GENDER_OPTIONS,
    validation: { enum: GENDER_OPTIONS, message: '请选择性别' },
  },
  {
    name: 'contactNumber',
    type: 'String',
    label: '联系电话',
    validation: { maxLength: 20, message: '联系电话不能超过20个字符' },
  },
  {
    name: 'email',
    type: 'String',
    label: '邮箱',
    validation: {
      pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
      message: '请输入有效的邮箱地址',
    },
  },
  {
    name: 'status',
    type: 'select',
    label: '状态',
    options: STATUS_OPTIONS,
    validation: { required: true, enum: STATUS_OPTIONS, message: '请选择状态' },
  },
  { name: 'department', type: 'String', label: '部门' },
  { name: 'position', type: 'String', label: '岗位' },
  { name: 'employeeNumber', type: 'String', label: '工号' },
  { name: 'accountExpiryDate', type: 'DateTime', label: '账号有效期' },
  { name: 'remarks', type: 'String', label: '备注' },
];

const TABLE_FIELDS: Array<EntityField & { key?: string }> = [
  { name: 'realName', key: 'realName', label: '姓名' },
  { name: 'username', key: 'username', label: '账号' },
  { name: 'status', key: 'status', label: '状态' },
  { name: 'contactNumber', key: 'contactNumber', label: '电话' },
  { name: 'email', key: 'email', label: '邮箱' },
];

interface SearchState {
  type: string;
  text: string;
  submitted: boolean;
}

const EMPTY_SEARCH: SearchState = { type: 'username', text: '', submitted: false };

export default function UserManagementPage() {
  const queryClient = useQueryClient();
  const columns = useMemo(() => buildColumns(TABLE_FIELDS), []);
  const [search, setSearch] = useState<SearchState>(EMPTY_SEARCH);
  const [formData, setFormData] = useState<Record<string, unknown>>({});
  const [formError, setFormError] = useState('');
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const { isOpen: isModalOpen, activeRow: editing, open, close } = useModalState();

  const query = useQuery<ManagedUser[]>({
    queryKey: ['users', search.type, search.text, search.submitted],
    queryFn: async () => {
      const keyword = search.text.trim();
      if (!search.submitted || !keyword) {
        return listUsers();
      }
      switch (search.type) {
        case 'username':
          return searchUsersByUsernamePrefix(keyword);
        case 'real-name':
          return searchUsersByRealNamePrefix(keyword);
        case 'status':
          return searchUsersByStatus(keyword);
        case 'department':
          return searchUsersByDepartment(keyword);
        case 'contact':
          return searchUsersByContact(keyword);
        default:
          return listUsers();
      }
    },
  });

  const rows = useMemo(() => {
    const users = query.data || [];
    if (search.submitted && search.type === 'email') {
      const keyword = search.text.trim().toLowerCase();
      if (!keyword) return users;
      return users.filter((user) =>
        String(user.email ?? '').toLowerCase().includes(keyword)
      );
    }
    return users;
  }, [query.data, search.submitted, search.type, search.text]);

  const refresh = () => queryClient.invalidateQueries({ queryKey: ['users'] });

  const createMutation = useMutation({
    mutationFn: (payload: Record<string, unknown>) => createUser(payload),
    onSuccess: refresh,
  });

  const updateMutation = useMutation({
    mutationFn: ({ userId, payload }: { userId: number; payload: Record<string, unknown> }) =>
      updateUser(userId, payload),
    onSuccess: refresh,
  });

  const deleteMutation = useMutation({
    mutationFn: (userId: number) => deleteUser(userId),
    onSuccess: refresh,
  });

  const handleOpenCreate = () => {
    setFormError('');
    setFieldErrors({});
    setFormData({ status: 'Active' });
    open();
  };

  const handleOpenEdit = (row: Record<string, unknown>) => {
    setFormError('');
    setFieldErrors({});
    setFormData({ ...row });
    open(row);
  };

  const handleCloseModal = () => {
    setFormError('');
    setFieldErrors({});
    close();
  };

  const { confirm: handleConfirmDelete, loading: deleteLoading } = useConfirm(
    async (...args: unknown[]) => {
      const row = args[0] as Record<string, unknown>;
      const userId = row?.userId as number | undefined;
      if (!userId) return;
      if (window.confirm('确定删除该用户吗？')) {
        await deleteMutation.mutateAsync(userId);
      }
    },
    {
      onSuccess: handleCloseModal,
      onError: (error) => setFormError(getErrorMessage(error)),
    }
  );

  const { confirm: handleConfirmSave, loading: saveLoading } = useConfirm(
    async () => {
      setFormError('');
      const payload = FORM_FIELDS.reduce<Record<string, unknown>>((acc, field) => {
        acc[field.name] = formData[field.name];
        return acc;
      }, {});
      const expiry = payload.accountExpiryDate;
      payload.accountExpiryDate = typeof expiry === 'string' && expiry ? formatDate(expiry) : null;
      const password = typeof payload.password === 'string' ? payload.password : '';
      if (password) {
        payload.password = password;
      } else {
        delete payload.password;
      }
      const editingUserId = editing?.userId as number | undefined;
      if (editingUserId) {
        await updateMutation.mutateAsync({ userId: editingUserId, payload });
      } else {
        await createMutation.mutateAsync(payload);
      }
    },
    {
      onSuccess: handleCloseModal,
      onError: (error) => setFormError(getErrorMessage(error)),
    }
  );

  const handleSaveClick = () => {
    const errors = validateEntityForm(FORM_FIELDS, formData);
    const password = String(formData.password ?? '');
    const editingUserId = editing?.userId as number | undefined;
    if (!editingUserId && !password) {
      errors.password = '新增用户时必须设置密码';
    }
    if (Object.keys(errors).length > 0) {
      setFormError('');
      setFieldErrors(errors);
      return;
    }
    setFieldErrors({});
    handleConfirmSave();
  };

  const handleSearch = () =>
    setSearch((prev) => ({ ...prev, submitted: true }));
  const handleClear = () => setSearch({ ...EMPTY_SEARCH, submitted: true });
  const handleTypeChange = (type: string) =>
    setSearch((prev) => ({ ...prev, type, text: '', submitted: false }));

  return (
    <PageLayout
      title="用户管理"
      subtitle="系统账号资料、状态与登录安全信息"
      headerActions={
        <button type="button" className="primary" onClick={handleOpenCreate}>
          创建新用户
        </button>
      }
    >
      <div className="panel">
        <SearchFilterBar
          options={SEARCH_OPTIONS}
          selectedType={search.type}
          onTypeChange={handleTypeChange}
          textValue={search.text}
          onTextChange={(value) => setSearch((prev) => ({ ...prev, text: value }))}
          startDate=""
          endDate=""
          onStartDateChange={() => {}}
          onEndDateChange={() => {}}
          onSearch={handleSearch}
          onClear={handleClear}
        />
      </div>

      {query.isError ? (
        <ErrorStateView message={getErrorMessage(query.error)} onRetry={() => query.refetch()} />
      ) : null}
      {query.isLoading ? <div className="placeholder">加载中...</div> : null}

      <DataTable
        columns={columns}
        rows={rows as Record<string, unknown>[]}
        idField="userId"
        onEdit={handleOpenEdit}
        onDelete={handleConfirmDelete}
      />

      <Modal
        isOpen={isModalOpen}
        title={editing ? '编辑用户' : '创建新用户'}
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
          fields={FORM_FIELDS}
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
          disabledFields={['userId']}
          fieldErrors={fieldErrors}
        />
      </Modal>
    </PageLayout>
  );
}
