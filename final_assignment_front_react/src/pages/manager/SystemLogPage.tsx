import { useNavigate } from 'react-router-dom';
import { useMemo } from 'react';
import PageLayout from '../../components/PageLayout';
import DataTable from '../../components/DataTable';
import ErrorStateView from '../../components/ErrorStateView';
import { useSystemLogs } from '../../hooks/useSystemLogs';
import { buildColumns } from '../../utils/buildColumns';
import { getErrorMessage } from '../../utils/errorMessages';
import type { EntityField } from '../../config/entityTypes';

const loginLogFields: Array<EntityField & { key?: string }> = [
  { name: 'username', key: 'username', label: '用户名' },
  { name: 'loginTime', key: 'loginTime', label: '登录时间', type: 'DateTime' },
  { name: 'loginResult', key: 'loginResult', label: '结果' },
  { name: 'loginIp', key: 'loginIp', label: 'IP' },
  { name: 'loginLocation', key: 'loginLocation', label: '位置' },
  { name: 'browserType', key: 'browserType', label: '浏览器' },
  { name: 'osType', key: 'osType', label: '系统' },
  { name: 'remarks', key: 'remarks', label: '备注' },
];

const operationLogFields: Array<EntityField & { key?: string }> = [
  { name: 'operationType', key: 'operationType', label: '操作类型' },
  { name: 'operationModule', key: 'operationModule', label: '模块' },
  { name: 'username', key: 'username', label: '用户' },
  { name: 'operationResult', key: 'operationResult', label: '结果' },
  { name: 'operationContent', key: 'operationContent', label: '内容' },
  { name: 'requestIp', key: 'requestIp', label: 'IP' },
  { name: 'operationTime', key: 'operationTime', label: '时间', type: 'DateTime' },
];

export default function SystemLogPage() {
  const navigate = useNavigate();
  const { overview, loginLogs, operationLogs } = useSystemLogs();
  const loginColumns = useMemo(() => buildColumns(loginLogFields), []);
  const operationColumns = useMemo(() => buildColumns(operationLogFields), []);

  const {
    data: overviewData,
    isLoading: overviewLoading,
    isError: overviewError,
    error: overviewQueryError,
    refetch: refetchOverview,
  } = overview;
  const {
    data: loginLogRows,
    isLoading: loginLogsLoading,
    isError: loginLogsError,
    error: loginLogsQueryError,
    refetch: refetchLoginLogs,
  } = loginLogs;
  const {
    data: operationLogRows,
    isLoading: operationLogsLoading,
    isError: operationLogsError,
    error: operationLogsQueryError,
    refetch: refetchOperationLogs,
  } = operationLogs;

  return (
    <PageLayout title="系统日志" subtitle="系统运行概览与近期审计">
      {overviewError ? (
        <ErrorStateView
          message={getErrorMessage(overviewQueryError)}
          onRetry={refetchOverview}
        />
      ) : null}
      {overviewLoading ? <div className="placeholder">加载中...</div> : null}
      {!overviewError ? (
        <div className="stat-grid">
          <div className="stat-card">
            <div className="stat-header">登录日志</div>
            <div className="stat-value">{overviewData?.loginLogCount ?? '-'}</div>
          </div>
          <div className="stat-card">
            <div className="stat-header">操作日志</div>
            <div className="stat-value">{overviewData?.operationLogCount ?? '-'}</div>
          </div>
          <div className="stat-card">
            <div className="stat-header">请求历史</div>
            <div className="stat-value">{overviewData?.requestHistoryCount ?? '-'}</div>
            <button type="button" className="link-button" onClick={() => navigate('/admin/requestHistory')}>
              前往检索
            </button>
          </div>
        </div>
      ) : null}

      <div className="panel">
        <h3>近期登录日志</h3>
        {loginLogsError ? (
          <ErrorStateView
            message={getErrorMessage(loginLogsQueryError)}
            onRetry={refetchLoginLogs}
          />
        ) : null}
        {loginLogsLoading ? <div className="placeholder">加载中...</div> : null}
        {!loginLogsError ? (
          <DataTable columns={loginColumns} rows={(loginLogRows as Record<string, unknown>[]) || []} />
        ) : null}
      </div>

      <div className="panel">
        <h3>近期操作日志</h3>
        {operationLogsError ? (
          <ErrorStateView
            message={getErrorMessage(operationLogsQueryError)}
            onRetry={refetchOperationLogs}
          />
        ) : null}
        {operationLogsLoading ? <div className="placeholder">加载中...</div> : null}
        {!operationLogsError ? (
          <DataTable
            columns={operationColumns}
            rows={(operationLogRows as Record<string, unknown>[]) || []}
          />
        ) : null}
      </div>
    </PageLayout>
  );
}
