/**
 * 备份与恢复管理页，对齐 Flutter BackupAndRestorePage。
 * 列表（按文件名/时间客户端筛选）+ 创建/编辑/恢复/删除/详情。
 * 仅 ADMIN/SUPER_ADMIN 可操作（对齐后端 @RolesAllowed）。
 */
import { useMemo, useState } from 'react';
import PageLayout from '../../components/PageLayout';
import Modal from '../../components/Modal';
import ErrorStateView from '../../components/ErrorStateView';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import {
  createBackup,
  deleteBackup,
  listBackups,
  restoreBackup,
  updateBackup,
  type BackupRestore,
} from '../../api/backup';
import { useAuth } from '../../auth/AuthContext';
import { formatDateTime } from '../../utils/format';
import { getErrorMessage } from '../../utils/errorMessages';

export default function BackupRestorePage() {
  const { auth } = useAuth();
  const canManage = (auth?.roles || []).some((role) => role.toUpperCase().includes('ADMIN'));
  const queryClient = useQueryClient();

  const [fileNameFilter, setFileNameFilter] = useState('');
  const [timeFilter, setTimeFilter] = useState('');
  const [toast, setToast] = useState<{ message: string; isError?: boolean } | null>(null);

  const [createOpen, setCreateOpen] = useState(false);
  const [editTarget, setEditTarget] = useState<BackupRestore | null>(null);
  const [detailTarget, setDetailTarget] = useState<BackupRestore | null>(null);
  const [form, setForm] = useState({ backupFileName: '', remarks: '' });
  const [saving, setSaving] = useState(false);

  const listQuery = useQuery({
    queryKey: ['backups'],
    queryFn: () => listBackups(),
    enabled: canManage,
  });

  const allBackups: BackupRestore[] = Array.isArray(listQuery.data) ? listQuery.data : [];

  const filteredBackups = useMemo(() => {
    let result = allBackups;
    if (fileNameFilter.trim()) {
      const q = fileNameFilter.trim().toLowerCase();
      result = result.filter((b) => (b.backupFileName || '').toLowerCase().includes(q));
    }
    if (timeFilter.trim()) {
      result = result.filter((b) => formatDateTime(b.backupTime).startsWith(timeFilter.trim()));
    }
    return result;
  }, [allBackups, fileNameFilter, timeFilter]);

  const flash = (message: string, isError?: boolean) => {
    setToast({ message, isError });
    window.setTimeout(() => setToast(null), 3000);
  };

  const refresh = () => queryClient.invalidateQueries({ queryKey: ['backups'] });

  const openCreate = () => {
    setForm({ backupFileName: '', remarks: '' });
    setCreateOpen(true);
  };

  const openEdit = (backup: BackupRestore) => {
    setForm({ backupFileName: backup.backupFileName || '', remarks: backup.remarks || '' });
    setEditTarget(backup);
  };

  const handleCreate = async () => {
    const name = form.backupFileName.trim();
    if (!name) {
      flash('文件名不能为空', true);
      return;
    }
    setSaving(true);
    try {
      await createBackup({
        backupFileName: name,
        backupTime: new Date().toISOString(),
        remarks: form.remarks.trim() || '手动创建的备份',
        status: 'PENDING',
      });
      flash('备份创建成功');
      setCreateOpen(false);
      await refresh();
    } catch (e) {
      flash(getErrorMessage(e), true);
    } finally {
      setSaving(false);
    }
  };

  const handleEdit = async () => {
    if (!editTarget?.backupId) return;
    const name = form.backupFileName.trim();
    if (!name) {
      flash('文件名不能为空', true);
      return;
    }
    setSaving(true);
    try {
      await updateBackup(editTarget.backupId, {
        ...editTarget,
        backupFileName: name,
        remarks: form.remarks.trim(),
      });
      flash('备份更新成功');
      setEditTarget(null);
      await refresh();
    } catch (e) {
      flash(getErrorMessage(e), true);
    } finally {
      setSaving(false);
    }
  };

  const handleRestore = async (backup: BackupRestore) => {
    if (!backup.backupId) return;
    if (!window.confirm(`确定恢复备份“${backup.backupFileName || ''}”吗？`)) return;
    try {
      await restoreBackup(backup);
      flash('恢复备份成功');
      await refresh();
    } catch (e) {
      flash(getErrorMessage(e), true);
    }
  };

  const handleDelete = async (backupId: number) => {
    if (!window.confirm('确定删除该备份吗？此操作不可撤销。')) return;
    try {
      await deleteBackup(backupId);
      flash('删除备份成功');
      await refresh();
    } catch (e) {
      flash(getErrorMessage(e), true);
    }
  };

  if (!canManage) {
    return (
      <PageLayout title="备份与恢复管理" subtitle="">
        <div className="placeholder">权限不足：仅管理员可访问此页面</div>
      </PageLayout>
    );
  }

  return (
    <PageLayout
      title="备份与恢复管理"
      subtitle="系统备份记录的创建、恢复与维护"
      headerActions={
        <button type="button" className="primary" onClick={openCreate}>
          创建新备份
        </button>
      }
    >
      {toast ? (
        <div className={toast.isError ? 'form-error' : 'form-success'}>{toast.message}</div>
      ) : null}

      <div className="backup-search-row">
        <input
          type="text"
          placeholder="按文件名搜索备份"
          value={fileNameFilter}
          onChange={(e) => setFileNameFilter(e.target.value)}
        />
        <input
          type="date"
          value={timeFilter}
          onChange={(e) => setTimeFilter(e.target.value)}
          aria-label="按备份时间搜索"
        />
      </div>

      {listQuery.isLoading ? <div className="placeholder">加载中...</div> : null}
      {listQuery.isError ? (
        <ErrorStateView message={getErrorMessage(listQuery.error)} onRetry={() => listQuery.refetch()} />
      ) : null}

      {!listQuery.isLoading && !listQuery.isError && filteredBackups.length === 0 ? (
        <div className="placeholder">没有找到备份记录</div>
      ) : null}

      {filteredBackups.length > 0 ? (
        <ul className="backup-list">
          {filteredBackups.map((backup) => (
            <li key={backup.backupId} className="backup-item">
              <div className="backup-item-main">
                <strong>{backup.backupFileName || '无'}</strong>
                <div className="backup-item-meta">
                  备份时间：{formatDateTime(backup.backupTime) || '--'}<br />
                  恢复时间：{formatDateTime(backup.restoreTime) || '--'}<br />
                  恢复状态：{backup.restoreStatus || '未恢复'}
                </div>
              </div>
              <div className="backup-item-actions">
                <button type="button" className="link-button" onClick={() => handleRestore(backup)}>
                  恢复
                </button>
                <button type="button" className="link-button" onClick={() => openEdit(backup)}>
                  编辑
                </button>
                <button
                  type="button"
                  className="link-button danger"
                  onClick={() => backup.backupId && handleDelete(backup.backupId)}
                >
                  删除
                </button>
                <button type="button" className="link-button" onClick={() => setDetailTarget(backup)}>
                  详情
                </button>
              </div>
            </li>
          ))}
        </ul>
      ) : null}

      <Modal
        isOpen={createOpen}
        title="创建备份"
        onClose={() => setCreateOpen(false)}
        footerActions={
          <div className="modal-actions">
            <button type="button" className="ghost" onClick={() => setCreateOpen(false)} disabled={saving}>
              取消
            </button>
            <button type="button" className="primary" onClick={handleCreate} disabled={saving}>
              {saving ? '保存中...' : '保存'}
            </button>
          </div>
        }
      >
        <BackupForm form={form} setForm={setForm} />
      </Modal>

      <Modal
        isOpen={Boolean(editTarget)}
        title="编辑备份"
        onClose={() => setEditTarget(null)}
        footerActions={
          <div className="modal-actions">
            <button type="button" className="ghost" onClick={() => setEditTarget(null)} disabled={saving}>
              取消
            </button>
            <button type="button" className="primary" onClick={handleEdit} disabled={saving}>
              {saving ? '保存中...' : '保存'}
            </button>
          </div>
        }
      >
        <BackupForm form={form} setForm={setForm} />
      </Modal>

      <Modal
        isOpen={Boolean(detailTarget)}
        title="备份详情"
        onClose={() => setDetailTarget(null)}
        footerActions={
          <div className="modal-actions">
            <button type="button" className="ghost" onClick={() => setDetailTarget(null)}>
              关闭
            </button>
          </div>
        }
      >
        {detailTarget ? (
          <div className="detail-grid">
            <DetailRow label="备份 ID" value={detailTarget.backupId} />
            <DetailRow label="文件名" value={detailTarget.backupFileName} />
            <DetailRow label="备份时间" value={formatDateTime(detailTarget.backupTime)} />
            <DetailRow label="恢复时间" value={formatDateTime(detailTarget.restoreTime)} />
            <DetailRow label="恢复状态" value={detailTarget.restoreStatus} />
            <DetailRow label="状态" value={detailTarget.status} />
            <DetailRow label="备注" value={detailTarget.remarks} />
          </div>
        ) : null}
      </Modal>
    </PageLayout>
  );
}

function BackupForm({
  form,
  setForm,
}: {
  form: { backupFileName: string; remarks: string };
  setForm: (f: { backupFileName: string; remarks: string }) => void;
}) {
  return (
    <div className="form-grid">
      <label className="form-field full">
        <span>文件名</span>
        <input
          type="text"
          value={form.backupFileName}
          onChange={(e) => setForm({ ...form, backupFileName: e.target.value })}
        />
      </label>
      <label className="form-field full">
        <span>备注</span>
        <textarea
          rows={3}
          value={form.remarks}
          onChange={(e) => setForm({ ...form, remarks: e.target.value })}
        />
      </label>
    </div>
  );
}

function DetailRow({ label, value }: { label: string; value: unknown }) {
  return (
    <div className="profile-tile">
      <span className="profile-tile-label">{label}</span>
      <span className="profile-tile-value">{value === undefined || value === null || value === '' ? '无' : String(value)}</span>
    </div>
  );
}
