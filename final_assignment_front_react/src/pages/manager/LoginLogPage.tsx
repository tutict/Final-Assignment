/**
 * 登录日志页，对齐 Flutter LoginLogPage。
 * 字段下拉检索（用户名/登录结果/时间范围）+ 服务端检索端点。
 * 时间范围为空时退回全量列表 + 客户端过滤（对齐 Flutter _applyFilters）。
 */
import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import PageLayout from '../../components/PageLayout';
import DataTable from '../../components/DataTable';
import SearchFilterBar, { type SearchTypeOption } from '../../components/SearchFilterBar';
import ErrorStateView from '../../components/ErrorStateView';
import {
  listLoginLogs,
  searchLoginLogsByUsername,
  searchLoginLogsByResult,
  searchLoginLogsByTimeRange,
  type LoginLog,
} from '../../api/logSearch';
import { buildColumns } from '../../utils/buildColumns';
import { getErrorMessage } from '../../utils/errorMessages';
import { toLocalDateEnd, toLocalDateStart } from '../../utils/format';
import type { EntityField } from '../../config/entityTypes';

const SEARCH_OPTIONS: SearchTypeOption[] = [
  { value: 'username', label: '按用户名', hint: '前缀匹配用户名' },
  { value: 'result', label: '按登录结果', hint: '例如 Success / Failed / Locked' },
  { value: 'time-range', label: '按时间范围', hint: '选择登录时间范围' },
];

const LOG_FIELDS: Array<EntityField & { key?: string }> = [
  { name: 'logId', key: 'logId', label: '日志ID' },
  { name: 'username', key: 'username', label: '用户名' },
  { name: 'loginTime', key: 'loginTime', label: '登录时间', type: 'DateTime' },
  { name: 'logoutTime', key: 'logoutTime', label: '登出时间', type: 'DateTime' },
  { name: 'loginResult', key: 'loginResult', label: '结果' },
  { name: 'failureReason', key: 'failureReason', label: '失败原因' },
  { name: 'loginIp', key: 'loginIp', label: 'IP' },
  { name: 'loginLocation', key: 'loginLocation', label: '位置' },
  { name: 'browserType', key: 'browserType', label: '浏览器' },
  { name: 'osType', key: 'osType', label: '系统' },
  { name: 'deviceType', key: 'deviceType', label: '设备' },
];

interface SearchState {
  type: string;
  text: string;
  startDate: string;
  endDate: string;
  submitted: boolean;
}

const EMPTY_SEARCH: SearchState = {
  type: 'username',
  text: '',
  startDate: '',
  endDate: '',
  submitted: false,
};

export default function LoginLogPage() {
  const columns = useMemo(() => buildColumns(LOG_FIELDS), []);
  const [search, setSearch] = useState<SearchState>(EMPTY_SEARCH);

  const query = useQuery<LoginLog[]>({
    queryKey: ['loginLogs', search.type, search.text, search.startDate, search.endDate, search.submitted],
    queryFn: async () => {
      if (!search.submitted) return listLoginLogs();
      if (search.type === 'username' && search.text.trim()) {
        return searchLoginLogsByUsername(search.text.trim());
      }
      if (search.type === 'result' && search.text.trim()) {
        return searchLoginLogsByResult(search.text.trim());
      }
      if (search.type === 'time-range' && search.startDate && search.endDate) {
        // 后端 LocalDateTime.parse 要求秒级本地时间，结束日取 23:59:59 纳入整天
        return searchLoginLogsByTimeRange(
          toLocalDateStart(search.startDate),
          toLocalDateEnd(search.endDate)
        );
      }
      return listLoginLogs();
    },
  });

  const handleSearch = () => setSearch((prev) => ({ ...prev, submitted: true }));
  const handleClear = () => setSearch({ ...EMPTY_SEARCH, submitted: true });
  const handleTypeChange = (type: string) =>
    setSearch((prev) => ({ ...prev, type, text: '', startDate: '', endDate: '', submitted: false }));

  const rows = (query.data || []).map((item) => item as unknown as Record<string, unknown>);

  return (
    <PageLayout title="登录日志" subtitle="用户登录、登出与失败记录">
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

      <DataTable columns={columns} rows={rows} idField="logId" />
    </PageLayout>
  );
}
