/**
 * 进度消息列表视图，对齐 Flutter ProgressMessagePageBody。
 * 头部统计 + 状态分类筛选 chips + 时间范围筛选 + 进度卡片列表。
 * 复用于管理员（ProgressManagementPage）与用户（OnlineProcessingProgressPage）。
 */
import { useNavigate } from 'react-router-dom';
import {
  formatProgressDateRange,
  progressStatusLabel,
  useProgress,
} from '../hooks/useProgress';
import type { ProgressItem } from '../api/progress';
import { getErrorMessage } from '../utils/errorMessages';
import { formatDateTime } from '../utils/format';
import ErrorStateView from './ErrorStateView';

interface ProgressMessageListProps {
  title: string;
  subtitle: string;
  roleLabel: string;
  emptyMessage: string;
  /** 管理员可创建/删除/变更状态 */
  canManage?: boolean;
}

export default function ProgressMessageList({
  title,
  subtitle,
  roleLabel,
  emptyMessage,
  canManage = false,
}: ProgressMessageListProps) {
  const navigate = useNavigate();
  const progress = useProgress({ canManage });
  const {
    items,
    totalCount,
    statusCategories,
    selectedStatus,
    startDate,
    endDate,
    hasActiveFilter,
    isLoading,
    isError,
    error,
    businessContext,
    refresh,
    filterByStatus,
    filterByTimeRange,
    clearFilters,
  } = progress;

  const handleOpen = (item: ProgressItem) => {
    if (item.id != null) {
      navigate(`/progressDetailPage/${item.id}`, { state: { progressItem: item } });
    }
  };

  const handleDateRangeSearch = () => {
    const start = window.prompt('开始日期（YYYY-MM-DD）');
    if (!start) return;
    const end = window.prompt('结束日期（YYYY-MM-DD）');
    if (!end) return;
    filterByTimeRange(start, end);
  };

  return (
    <div className="progress-message">
      <div className="progress-message-header">
        <div className="progress-message-heading">
          <h3>{title}</h3>
          <span className="progress-role-badge">{roleLabel}</span>
        </div>
        <p className="progress-subtitle">{subtitle}</p>
        <div className="progress-summary">
          <span className="progress-summary-pill">全部 {totalCount}</span>
          <span className="progress-summary-pill">当前显示 {items.length}</span>
          {hasActiveFilter ? (
            <span className="progress-summary-pill">
              筛选 {selectedStatus ? progressStatusLabel(selectedStatus) : formatProgressDateRange(startDate, endDate)}
            </span>
          ) : null}
          <button type="button" className="ghost" onClick={refresh} disabled={isLoading}>
            {isLoading ? '刷新中...' : '刷新'}
          </button>
        </div>
      </div>

      <div className="progress-filter-bar">
        <div className="progress-status-chips">
          <button
            type="button"
            className={`chip ${!hasActiveFilter ? 'chip-selected' : ''}`}
            onClick={clearFilters}
          >
            全部
          </button>
          {statusCategories.map((status) => (
            <button
              key={status}
              type="button"
              className={`chip ${selectedStatus === status ? 'chip-selected' : ''}`}
              onClick={() => filterByStatus(status)}
            >
              {progressStatusLabel(status)}
            </button>
          ))}
        </div>
        <div className="progress-filter-actions">
          <button type="button" className="ghost" onClick={handleDateRangeSearch}>
            {formatProgressDateRange(startDate, endDate)}
          </button>
          <button
            type="button"
            className="ghost"
            onClick={clearFilters}
            disabled={!hasActiveFilter}
          >
            清除筛选
          </button>
        </div>
      </div>

      {isError ? (
        <ErrorStateView message={getErrorMessage(error)} onRetry={refresh} />
      ) : null}

      {isLoading ? (
        <div className="placeholder">正在加载进度消息...</div>
      ) : null}

      {!isLoading && !isError && items.length === 0 ? (
        <div className="placeholder">{emptyMessage}</div>
      ) : null}

      {!isLoading && !isError && items.length > 0 ? (
        <ul className="progress-card-list">
          {items.map((item) => (
            <li
              key={item.id ?? item.title + item.submitTime}
              className={`progress-card progress-status-${(item.status || '').toLowerCase()}`}
            >
              <button type="button" className="progress-card-main" onClick={() => handleOpen(item)}>
                <span className={`progress-status-icon progress-status-icon-${(item.status || '').toLowerCase()}`}>
                  {progressStatusLabel(item.status).charAt(0)}
                </span>
                <span className="progress-card-body">
                  <span className="progress-card-top">
                    <span className="progress-card-title">{item.title || '未命名进度'}</span>
                    <span className={`progress-status-badge progress-status-badge-${(item.status || '').toLowerCase()}`}>
                      {progressStatusLabel(item.status)}
                    </span>
                  </span>
                  <span className="progress-card-meta">
                    <span className="meta-pill">⏱ {formatDateTime(item.submitTime)}</span>
                    {item.username ? <span className="meta-pill">👤 {item.username}</span> : null}
                    <span className="meta-pill">🔗 {businessContext(item)}</span>
                  </span>
                  {item.details ? (
                    <span className="progress-card-details">{item.details}</span>
                  ) : null}
                </span>
              </button>
              {canManage && item.id != null ? (
                <div className="progress-card-menu">
                  <button
                    type="button"
                    className="link-button"
                    onClick={() => handleOpen(item)}
                  >
                    详情
                  </button>
                  {progress.deleteProgress ? (
                    <button
                      type="button"
                      className="link-button danger"
                      onClick={() => {
                        if (window.confirm('确定删除该进度记录吗？此操作不可撤销。')) {
                          void progress.deleteProgress?.(item.id as number);
                        }
                      }}
                    >
                      删除
                    </button>
                  ) : null}
                </div>
              ) : null}
            </li>
          ))}
        </ul>
      ) : null}
    </div>
  );
}
