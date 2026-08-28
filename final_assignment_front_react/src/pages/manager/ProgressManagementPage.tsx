/**
 * 管理员进度管理页，对齐 Flutter ProgressManagementPage。
 * 复用 ProgressMessageList，提供状态分类筛选、时间范围筛选、新建/删除进度。
 */
import { useState } from 'react';
import PageLayout from '../../components/PageLayout';
import Modal from '../../components/Modal';
import ProgressMessageList from '../../components/ProgressMessageList';
import { useProgress } from '../../hooks/useProgress';
import { useAuth } from '../../auth/AuthContext';

export default function ProgressManagementPage() {
  const { auth } = useAuth();
  const canManage = (auth?.roles || []).some((role) => role.toUpperCase().includes('ADMIN'));
  const progress = useProgress({ canManage });
  const [createOpen, setCreateOpen] = useState(false);
  const [title, setTitle] = useState('');
  const [details, setDetails] = useState('');

  const handleCreate = async () => {
    const trimmed = title.trim();
    if (!trimmed) return;
    if (progress.createProgress) {
      await progress.createProgress({ title: trimmed, details: details.trim() || undefined });
    }
    setTitle('');
    setDetails('');
    setCreateOpen(false);
  };

  return (
    <PageLayout
      title="进度管理"
      subtitle="集中查看用户提交进度、关联业务和处理状态"
      headerActions={
        canManage ? (
          <button type="button" className="primary" onClick={() => setCreateOpen(true)}>
            新建进度
          </button>
        ) : null
      }
    >
      {!canManage ? (
        <div className="placeholder">权限不足：仅管理员可访问进度管理</div>
      ) : (
        <ProgressMessageList
          title="进度管理"
          subtitle="集中查看用户提交进度、关联业务和处理状态"
          roleLabel="管理员端"
          emptyMessage="暂无进度记录"
          canManage={canManage}
        />
      )}

      <Modal
        isOpen={createOpen}
        title="创建进度"
        onClose={() => setCreateOpen(false)}
        footerActions={
          <div className="modal-actions">
            <button type="button" className="ghost" onClick={() => setCreateOpen(false)}>
              取消
            </button>
            <button type="button" className="primary" onClick={handleCreate} disabled={!title.trim()}>
              提交
            </button>
          </div>
        }
      >
        <div className="form-grid">
          <label className="form-field full">
            <span>标题</span>
            <input type="text" value={title} onChange={(e) => setTitle(e.target.value)} />
          </label>
          <label className="form-field full">
            <span>详情（可选）</span>
            <textarea rows={4} value={details} onChange={(e) => setDetails(e.target.value)} />
          </label>
        </div>
      </Modal>
    </PageLayout>
  );
}
