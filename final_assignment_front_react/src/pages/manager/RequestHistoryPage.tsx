/**
 * 请求历史搜索页（对齐后端 /api/system/logs/requests/search/{field}）。
 * Flutter 端无对应 UI——本页基于 API 契约直接构建。
 *
 * 九个搜索字段：idempotency / method / url / business-type / business-id /
 * status / user / ip / time-range。time-range 使用起止日期；其余使用单值输入。
 */
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import PageLayout from '../../components/PageLayout';
import DataTable from '../../components/DataTable';
import ErrorStateView from '../../components/ErrorStateView';
import Modal from '../../components/Modal';
import {
  searchRequestHistory,
  getRequestHistory,
  type SysRequestHistory,
} from '../../api/systemLogs';
import type { RequestHistorySearchField } from '../../constants/apiPaths';
import type { DataTableColumn } from '../../components/DataTable';
import { formatDateTime } from '../../utils/format';

interface FieldOption {
  value: RequestHistorySearchField;
  label: string;
  hint: string;
}

const FIELD_OPTIONS: FieldOption[] = [
  { value: 'idempotency', label: '幂等键', hint: '输入 Idempotency-Key' },
  { value: 'method', label: '请求方法', hint: '例如 GET / POST' },
  { value: 'url', label: '请求 URL', hint: '部分匹配请求路径' },
  { value: 'business-type', label: '业务类型', hint: '例如 offense / appeal' },
  { value: 'business-id', label: '业务 ID', hint: '业务主键（数字）' },
  { value: 'status', label: '业务状态', hint: 'PROCESSING / SUCCESS / FAILED' },
  { value: 'user', label: '用户 ID', hint: '操作用户 ID（数字）' },
  { value: 'ip', label: '请求 IP', hint: '客户端 IP 地址' },
  { value: 'time-range', label: '时间范围', hint: '选择起止日期' },
];

const COLUMNS: DataTableColumn[] = [
  { key: 'id', label: 'ID' },
  { key: 'idempotencyKey', label: '幂等键' },
  { key: 'requestMethod', label: '方法' },
  { key: 'requestUrl', label: 'URL' },
  { key: 'businessType', label: '业务类型' },
  { key: 'businessId', label: '业务ID' },
  { key: 'businessStatus', label: '业务状态' },
  { key: 'userId', label: '用户' },
  { key: 'requestIp', label: 'IP' },
  {
    key: 'createdTime',
    label: '创建时间',
    render: (row) => formatDateTime(row.createdTime),
  },
];

const PAGE_SIZE = 20;

export default function RequestHistoryPage() {
  const [field, setField] = useState<RequestHistorySearchField>('idempotency');
  const [value, setValue] = useState('');
  const [startTime, setStartTime] = useState('');
  const [endTime, setEndTime] = useState('');
  const [page, setPage] = useState(1);
  const [submitted, setSubmitted] = useState<{
    field: RequestHistorySearchField;
    value: string;
    startTime: string;
    endTime: string;
    page: number;
  } | null>(null);

  const isTimeRange = field === 'time-range';

  const buildSearchValue = (): string => {
    if (isTimeRange) {
      // 对齐 api/systemLogs.ts FIELD_PARAMS.time-range：以 "~" 拼接，空侧表示开放区间
      return `${startTime}~${endTime}`;
    }
    return value.trim();
  };

  const handleSubmit = (nextPage = 1) => {
    const searchValue = buildSearchValue();
    setPage(nextPage);
    setSubmitted({
      field,
      value: searchValue,
      startTime,
      endTime,
      page: nextPage,
    });
  };

  const handleReset = () => {
    setValue('');
    setStartTime('');
    setEndTime('');
    setSubmitted(null);
    setPage(1);
  };

  const query = useQuery({
    queryKey: ['requestHistory', submitted],
    queryFn: () => {
      if (!submitted) return [] as SysRequestHistory[];
      return searchRequestHistory(submitted.field, submitted.value, submitted.page, PAGE_SIZE);
    },
    enabled: submitted !== null,
  });

  const [detailId, setDetailId] = useState<string | number | null>(null);
  const detailQuery = useQuery({
    queryKey: ['requestHistory', 'detail', detailId],
    queryFn: () => getRequestHistory(detailId as string | number),
    enabled: detailId !== null,
  });

  const currentOption = FIELD_OPTIONS.find((option) => option.value === field);

  return (
    <PageLayout title="请求历史检索" subtitle="按幂等键 / 方法 / URL / 业务 / 状态 / 用户 / IP / 时间检索链路">
      <div className="panel">
        <div className="request-search-bar">
          <select
            value={field}
            onChange={(event) => {
              setField(event.target.value as RequestHistorySearchField);
              setValue('');
              setStartTime('');
              setEndTime('');
            }}
          >
            {FIELD_OPTIONS.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>

          {isTimeRange ? (
            <div className="request-date-range">
              <input
                type="date"
                value={startTime}
                onChange={(event) => setStartTime(event.target.value)}
                aria-label="开始日期"
              />
              <span>至</span>
              <input
                type="date"
                value={endTime}
                onChange={(event) => setEndTime(event.target.value)}
                aria-label="结束日期"
              />
            </div>
          ) : (
            <input
              type="text"
              value={value}
              placeholder={currentOption?.hint || '输入检索值'}
              onChange={(event) => setValue(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === 'Enter') handleSubmit(1);
              }}
            />
          )}

          <button type="button" className="primary" onClick={() => handleSubmit(1)}>
            检索
          </button>
          <button type="button" className="ghost" onClick={handleReset}>
            重置
          </button>
        </div>
      </div>

      {query.isError ? (
        <ErrorStateView message="请求历史检索失败，请重试" onRetry={() => query.refetch()} />
      ) : null}

      <DataTable
        columns={COLUMNS}
        rows={(query.data || []).map((item) => item as unknown as Record<string, unknown>)}
        onView={(row) => {
          const id = row.id;
          if (id !== undefined && id !== null) setDetailId(id as string | number);
        }}
      />

      {submitted && query.data ? (
        <div className="request-pagination">
          <button
            type="button"
            className="ghost"
            onClick={() => handleSubmit(Math.max(1, page - 1))}
            disabled={page <= 1 || query.isLoading}
          >
            上一页
          </button>
          <span className="request-page-info">第 {page} 页</span>
          <button
            type="button"
            className="ghost"
            onClick={() => handleSubmit(page + 1)}
            disabled={query.data.length < PAGE_SIZE || query.isLoading}
          >
            下一页
          </button>
        </div>
      ) : null}

      <Modal
        isOpen={detailId !== null}
        title="请求历史详情"
        onClose={() => setDetailId(null)}
        wide
      >
        {detailQuery.isLoading ? <div className="placeholder">加载中...</div> : null}
        {detailQuery.isError ? (
          <ErrorStateView message="加载详情失败" onRetry={() => detailQuery.refetch()} />
        ) : null}
        {detailQuery.data ? (
          <div className="detail-grid">
            <DetailTile label="ID" value={detailQuery.data.id} />
            <DetailTile label="幂等键" value={detailQuery.data.idempotencyKey} />
            <DetailTile label="请求方法" value={detailQuery.data.requestMethod} />
            <DetailTile label="请求 URL" value={detailQuery.data.requestUrl} />
            <DetailTile label="业务类型" value={detailQuery.data.businessType} />
            <DetailTile label="业务 ID" value={detailQuery.data.businessId} />
            <DetailTile label="业务状态" value={detailQuery.data.businessStatus} />
            <DetailTile label="用户 ID" value={detailQuery.data.userId} />
            <DetailTile label="请求 IP" value={detailQuery.data.requestIp} />
            <DetailTile label="创建时间" value={formatDateTime(detailQuery.data.createdTime)} />
            <DetailTile label="修改时间" value={formatDateTime(detailQuery.data.modifiedTime)} />
            <div className="form-field full">
              <span>请求参数</span>
              <pre className="request-params">{detailQuery.data.requestParams || '-'}</pre>
            </div>
          </div>
        ) : null}
      </Modal>
    </PageLayout>
  );
}

function DetailTile({ label, value }: { label: string; value?: string | number | null }) {
  return (
    <div className="profile-tile">
      <span className="profile-tile-label">{label}</span>
      <span className="profile-tile-value">{value || value === 0 ? String(value) : '-'}</span>
    </div>
  );
}
