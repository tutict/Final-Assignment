import { useParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import PageLayout from '../../components/PageLayout';
import ErrorStateView from '../../components/ErrorStateView';
import StatusPill from '../../components/StatusPill';
import { getEntity } from '../../api/entities';
import { entityConfigs } from '../../config/entities';
import { getErrorMessage } from '../../utils/errorMessages';
import { formatDateTime } from '../../utils/format';

interface ProgressItem {
  id?: number | string;
  businessType?: string;
  businessId?: number | string;
  businessStatus?: string;
  requestMethod?: string;
  requestUrl?: string;
  userId?: number | string;
  createdTime?: string;
  modifiedTime?: string;
  [key: string]: unknown;
}

const TIMELINE_STAGES: Array<{ key: string; label: string }> = [
  { key: 'PROCESSING', label: '处理中' },
  { key: 'SUCCESS', label: '处理成功' },
  { key: 'FAILED', label: '处理失败' },
];

export default function ProgressDetailPage() {
  const { id } = useParams();

  const query = useQuery({
    queryKey: ['progress', id],
    queryFn: () => getEntity<ProgressItem>(entityConfigs.progress.basePath, String(id || '')),
    enabled: Boolean(id),
  });

  const item = (query.data || {}) as ProgressItem;

  return (
    <PageLayout title="进度详情" subtitle={`记录编号：${id || '-'}`}>
      {query.isLoading ? <div className="placeholder">加载中...</div> : null}
      {query.isError ? (
        <ErrorStateView
          message={getErrorMessage(query.error)}
          onRetry={() => void query.refetch()}
        />
      ) : null}
      {query.data ? (
        <div className="progress-detail">
          <div className="detail-grid">
            <div><strong>业务类型：</strong>{item.businessType || '-'}</div>
            <div><strong>业务 ID：</strong>{item.businessId ?? '-'}</div>
            <div>
              <strong>业务状态：</strong>
              {item.businessStatus ? <StatusPill value={item.businessStatus} /> : '-'}
            </div>
            <div><strong>请求方法：</strong>{item.requestMethod || '-'}</div>
            <div><strong>请求地址：</strong>{item.requestUrl || '-'}</div>
            <div><strong>用户 ID：</strong>{item.userId ?? '-'}</div>
            <div><strong>创建时间：</strong>{formatDateTime(item.createdTime)}</div>
            <div><strong>更新时间：</strong>{formatDateTime(item.modifiedTime)}</div>
          </div>
          <div className="panel">
            <h3>处理时间线</h3>
            <ul className="timeline">
              {TIMELINE_STAGES.map((stage) => {
                const reached =
                  stage.key === 'PROCESSING' && Boolean(item.businessStatus) ||
                  item.businessStatus === stage.key;
                return (
                  <li key={stage.key} className={reached ? 'is-reached' : ''}>
                    <span className="timeline-dot" />
                    <div>
                      <strong>{stage.label}</strong>
                      <span>{reached ? formatDateTime(item.modifiedTime) : '尚未到达'}</span>
                    </div>
                  </li>
                );
              })}
            </ul>
          </div>
        </div>
      ) : null}
    </PageLayout>
  );
}
