/**
 * 操作日志页，对齐 Flutter OperationLogPage。
 * 字段下拉检索（用户ID/操作结果/时间范围）+ 服务端检索端点。
 * time-range 调用 /api/logs/operation/search/time-range（对齐 Flutter 的 endTime +1 天）。
 */
import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import PageLayout from '../../components/PageLayout';
import DataTable from '../../components/DataTable';
import SearchFilterBar, { type SearchTypeOption } from '../../components/SearchFilterBar';
import ErrorStateView from '../../components/ErrorStateView';
import {
  listOperationLogs,
  searchOperationLogsByUser,
  searchOperationLogsByResult,
  searchOperationLogsByTimeRange,
  type OperationLog,
} from '../../api/logSearch';
import { buildColumns } from '../../utils/buildColumns';
import { getErrorMessage } from '../../utils/errorMessages';
import type { EntityField } from '../../config/entityTypes';

const SEARCH_OPTIONS: SearchTypeOption[] = [
  { value: 'userId', label: '按用户ID', hint: '精确匹配用户 ID（数字）' },
  { value: 'operationResult', label: '按操作结果', hint: '例如 Success / Failed / Exception' },
  { value: 'time-range', label: '按时间范围', hint: '选择操作时间范围' },
];

const LOG_FIELDS: Array<EntityField & { key?: string }> = [
  { name: 'logId', key: 'logId', label: '日志ID' },
  { name: 'operationType', key: 'operationType', label: '操作类型' },
  { name: 'operationModule', key: 'operationModule', label: '模块' },
  { name: 'operationFunction', key: 'operationFunction', label: '功能' },
  { name: 'operationContent', key: 'operationContent', label: '操作内容' },
  { name: 'operationTime', key: 'operationTime', label: '操作时间', type: 'DateTime' },
  { name: 'username', key: 'username', label: '用户' },
  { name: 'requestMethod', key: 'requestMethod', label: '方法' },
  { name: 'requestUrl', key: 'requestUrl', label: 'URL' },
  { name: 'requestIp', key: 'requestIp', label: 'IP' },
  { name: 'operationResult', key: 'operationResult', label: '结果' },
  { name: 'errorMessage', key: 'errorMessage', label: '错误信息' },
  { name: 'executionTime', key: 'executionTime', label: '耗时(ms)' },
];

interface SearchState {
  type: string;
  text: string;
  startDate: string;
  endDate: string;
  submitted: boolean;
}

const EMPTY_SEARCH: SearchState = {
  type: 'userId',
  text: '',
  startDate: '',
  endDate: '',
  submitted: false,
};

function toIsoStartOfDay(date: string): string {
  return date ? `${date}T00:00:00` : '';
}

function toIsoEndOfDay(date: string): string {
  // 对齐 Flutter operation_log_page：endTime +1 天
  if (!date) return '';
  const d = new Date(`${date}T00:00:00`);
  d.setDate(d.getDate() + 1);
  return d.toISOString().slice(0, 19);
}

export default function OperationLogPage() {
  const columns = useMemo(() => buildColumns(LOG_FIELDS), []);
  const [search, setSearch] = useState<SearchState>(EMPTY_SEARCH);

  const query = useQuery<OperationLog[]>({
    queryKey: ['operationLogs', search.type, search.text, search.startDate, search.endDate, search.submitted],
    queryFn: async () => {
      if (!search.submitted) return listOperationLogs();
      if (search.type === 'userId' && search.text.trim()) {
        const userId = Number(search.text.trim());
        if (!Number.isNaN(userId)) return searchOperationLogsByUser(userId);
      }
      if (search.type === 'operationResult' && search.text.trim()) {
        return searchOperationLogsByResult(search.text.trim());
      }
      if (search.type === 'time-range' && search.startDate && search.endDate) {
        return searchOperationLogsByTimeRange(
          toIsoStartOfDay(search.startDate),
          toIsoEndOfDay(search.endDate)
        );
      }
      return listOperationLogs();
    },
  });

  const handleSearch = () => setSearch((prev) => ({ ...prev, submitted: true }));
  const handleClear = () => setSearch({ ...EMPTY_SEARCH, submitted: true });
  const handleTypeChange = (type: string) =>
    setSearch((prev) => ({ ...prev, type, text: '', startDate: '', endDate: '', submitted: false }));

  const rows = (query.data || []).map((item) => item as unknown as Record<string, unknown>);

  return (
    <PageLayout title="操作日志" subtitle="后台操作与审计追踪">
      <div className="panel">
        <SearchFilterBar
          options={SEARCH_OPTIONS}
          selectedType={search.type}
          onTypeChange={handleTypeChange}
          textValue={search.text}
          onTextChange={(value) => setSearch((prev) => ({ ...prev, text: value }))}
          startDate={search.startDate}
          endDate={search.endDate}
          onStartDateChange={(value) => setSearch((prev) => ({ ...prev, startDate: value }))}
          onEndDateChange={(value) => setSearch((prev) => ({ ...prev, endDate: value }))}
          onSearch={handleSearch}
          onClear={handleClear}
        />
      </div>

      {query.isError ? (
        <ErrorStateView message={getErrorMessage(query.error)} onRetry={() => query.refetch()} />
      ) : null}
      {query.isLoading ? <div className="placeholder">加载中...</div> : null}

      <DataTable columns={columns} rows={rows} />
    </PageLayout>
  );
}
