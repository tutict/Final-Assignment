/**
 * 进度详情页，对齐 Flutter ProgressDetailPage。
 * 摘要面板 + 办理时间线 + 关联业务 + 详情内容，管理员可更新状态/删除。
 * 优先取路由 state.progressItem（来自列表页传入），否则按 id 拉取后端 GET /api/progress/{id}。
 */
import { useState } from 'react';
import { useLocation, useNavigate, useParams } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import PageLayout from '../../components/PageLayout';
import ErrorStateView from '../../components/ErrorStateView';
import { deleteProgress, getProgress, type ProgressItem } from '../../api/progress';
import {
  progressStatusLabel,
  useProgress,
} from '../../hooks/useProgress';
import { useAuth } from '../../auth/AuthContext';
import { formatDateTime } from '../../utils/format';
import { getErrorMessage } from '../../utils/errorMessages';

const TIMELINE_STAGES = [
  { status: 'Pending', label: '等待受理', desc: '业务已提交，等待管理员核验材料。' },
  { status: 'Processing', label: '正在处理', desc: '管理员正在核对业务信息和处理意见。' },
  { status: 'Completed', label: '处理完成', desc: '业务已有办理结果，可查看详情说明。' },
  { status: 'Archived', label: '记录归档', desc: '该进度已归档，后续作为历史记录留存。' },
];

interface RouteState {
  progressItem?: ProgressItem;
}

export default function ProgressDetailPage() {
  const { id } = useParams();
  const location = useLocation();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { auth } = useAuth();
  const canManage = (auth?.roles || []).some((role) => role.toUpperCase().includes('ADMIN'));
  const progress = useProgress({ canManage });
  const [toast, setToast] = useState<{ message: string; isError?: boolean } | null>(null);

  const passedItem = (location.state as RouteState | null)?.progressItem;

  const query = useQuery({
    queryKey: ['progress', 'detail', id],
    queryFn: () => getProgress(Number(id)),
    enabled: Boolean(id) && !passedItem,
  });

  const item: ProgressItem | undefined = passedItem || query.data;
  const isLoading = !passedItem && query.isLoading;
  const isError = !passedItem && query.isError;
  const error = query.error;

  const flash = (message: string, isError?: boolean) => {
    setToast({ message, isError });
    window.setTimeout(() => setToast(null), 3000);
  };

  const handleUpdateStatus = async (status: string) => {
    if (item?.id == null) return;
    if (item.status === status) return;
    try {
      if (progress.updateStatus) {
        await progress.updateStatus(item.id, status);
      }
      await queryClient.invalidateQueries({ queryKey: ['progress'] });
      flash(`进度状态已更新为${progressStatusLabel(status)}`);
    } catch (e) {
      flash(getErrorMessage(e), true);
    }
  };

  const handleDelete = async () => {
    if (item?.id == null) return;
    if (!window.confirm(`确定删除“${item.title || '未命名进度'}”吗？此操作不可撤销。`)) return;
    try {
      await deleteProgress(item.id);
      await queryClient.invalidateQueries({ queryKey: ['progress'] });
      navigate(-1);
    } catch (e) {
      flash(getErrorMessage(e), true);
    }
  };

  const currentIndex = TIMELINE_STAGES.findIndex((s) => s.status === item?.status);
  const links = buildBusinessLinks(item);

  return (
    <PageLayout title="进度详情" subtitle={`记录编号：${item?.id ?? id ?? '-'}`}>
      {toast ? (
        <div className={toast.isError ? 'form-error' : 'form-success'}>{toast.message}</div>
      ) : null}

      {isLoading ? <div className="placeholder">加载中...</div> : null}
      {isError ? (
        <ErrorStateView message={getErrorMessage(error)} onRetry={() => query.refetch()} />
      ) : null}

      {item ? (
        <div className="progress-detail">
          <div className="panel">
            <div className="progress-detail-status-row">
              <span className={`progress-status-badge progress-status-badge-${(item.status || '').toLowerCase()}`}>
                {progressStatusLabel(item.status)}
              </span>
              <span className="meta-pill">进度编号 #{item.id ?? '未生成'}</span>
            </div>
            <h3 className="progress-detail-title">{item.title || '未命名进度'}</h3>
            <p className="progress-detail-context">{buildContextSummary(item)}</p>
            <div className="detail-grid">
              <FactTile label="提交用户" value={item.username || '未记录'} />
              <FactTile label="提交时间" value={formatDateTime(item.submitTime)} />
              <FactTile label="当前状态" value={progressStatusLabel(item.status)} />
              <FactTile label="关联数量" value={`${links.length} 项`} />
            </div>
          </div>

          <div className="panel">
            <h3>办理时间线</h3>
            <p className="panel-subtitle">按当前状态生成的办理节点</p>
            <ul className="progress-timeline">
              {TIMELINE_STAGES.map((stage, index) => {
                const done = currentIndex > index;
                const current = currentIndex === index;
                return (
                  <li
                    key={stage.status}
                    className={`progress-timeline-row ${done ? 'is-done' : ''} ${current ? 'is-current' : ''}`}
                  >
                    <span className="timeline-dot">{done ? '✓' : index + 1}</span>
                    <div className="timeline-content">
                      <strong>{stage.label}</strong>
                      <span>{stage.desc}</span>
                    </div>
                  </li>
                );
              })}
            </ul>
          </div>

          <div className="panel">
            <h3>关联业务</h3>
            <p className="panel-subtitle">
              {links.length === 0 ? '暂无关联业务编号' : '由后端进度记录中的关联字段生成'}
            </p>
            {links.length === 0 ? (
              <div className="placeholder-inline">这条进度暂未绑定申诉、罚款、车辆或违法记录。</div>
            ) : (
              <div className="progress-business-links">
                {links.map((link) => (
                  <span key={link.label} className="progress-business-pill">
                    {link.label} #{link.id}
                  </span>
                ))}
              </div>
            )}
          </div>

          <div className="panel">
            <h3>详情内容</h3>
            <p className="panel-subtitle">来自进度记录的业务说明或请求参数</p>
            <div className="progress-details-text">
              {formatDetails(item.details)}
            </div>
          </div>

          {canManage && item.id != null ? (
            <div className="panel">
              <h3>管理员操作</h3>
              <p className="panel-subtitle">更新办理状态或删除当前进度</p>
              <div className="progress-admin-actions">
                {TIMELINE_STAGES.filter((s) => s.status !== 'Pending').map((stage) => (
                  <button
                    key={stage.status}
                    type="button"
                    className="ghost"
                    disabled={item.status === stage.status}
                    onClick={() => handleUpdateStatus(stage.status)}
                  >
                    设为{stage.label}
                  </button>
                ))}
                <button type="button" className="danger" onClick={handleDelete}>
                  删除进度记录
                </button>
              </div>
            </div>
          ) : null}
        </div>
      ) : null}
    </PageLayout>
  );
}

function FactTile({ label, value }: { label: string; value: string }) {
  return (
    <div className="fact-tile">
      <span className="fact-tile-label">{label}</span>
      <span className="fact-tile-value">{value}</span>
    </div>
  );
}

interface BusinessLink {
  label: string;
  id: number;
}

function buildBusinessLinks(item?: ProgressItem): BusinessLink[] {
  if (!item) return [];
  const links: BusinessLink[] = [];
  if (item.appealId != null) links.push({ label: '申诉', id: item.appealId });
  if (item.deductionId != null) links.push({ label: '扣分', id: item.deductionId });
  if (item.driverId != null) links.push({ label: '司机', id: item.driverId });
  if (item.fineId != null) links.push({ label: '罚款', id: item.fineId });
  if (item.vehicleId != null) links.push({ label: '车辆', id: item.vehicleId });
  if (item.offenseId != null) links.push({ label: '违法', id: item.offenseId });
  return links;
}

function buildContextSummary(item?: ProgressItem): string {
  const links = buildBusinessLinks(item);
  if (links.length === 0) return '暂无关联业务记录';
  return links.map((l) => `${l.label} #${l.id}`).join(' / ');
}

function formatDetails(details?: string): string {
  const trimmed = (details || '').trim();
  if (!trimmed) return '暂无详情内容。';
  try {
    const parsed = JSON.parse(trimmed);
    if (typeof parsed === 'object' && parsed !== null) {
      return JSON.stringify(parsed, null, 2);
    }
    return String(parsed);
  } catch {
    return trimmed;
  }
}
