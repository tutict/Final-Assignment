import React, { useMemo } from 'react';
import PageLayout from '../../components/PageLayout.jsx';
import DataTable from '../../components/DataTable.jsx';
import ErrorStateView from '../../components/ErrorStateView.jsx';
import { useSystemLogs } from '../../hooks/useSystemLogs.js';
import { buildColumns } from '../../utils/buildColumns.js';

const loginLogFields = [
  { key: 'username', label: '用户名' },
  { key: 'loginTime', label: '登录时间', type: 'DateTime' },
  { key: 'loginResult', label: '结果' },
  { key: 'loginIp', label: 'IP' },
];

const operationLogFields = [
  { key: 'operationType', label: '操作类型' },
  { key: 'operationModule', label: '模块' },
  { key: 'username', label: '用户' },
  { key: 'operationTime', label: '时间', type: 'DateTime' },
];

export default function SystemLogPage() {
  const { overview, loginLogs, operationLogs } = useSystemLogs();
  const loginColumns = useMemo(() => buildColumns(loginLogFields), []);
  const operationColumns = useMemo(() => buildColumns(operationLogFields), []);

  const {
    data: overviewData,
    isLoading: overviewLoading,
    isError: overviewError,
    refetch: refetchOverview,
  } = overview;
  const {
    data: loginLogRows,
    isLoading: loginLogsLoading,
    isError: loginLogsError,
    refetch: refetchLoginLogs,
  } = loginLogs;
  const {
    data: operationLogRows,
    isLoading: operationLogsLoading,
    isError: operationLogsError,
    refetch: refetchOperationLogs,
  } = operationLogs;

  return (
    <PageLayout title="系统日志" subtitle="系统运行概览与近期审计">
      {overviewError ? (
        <ErrorStateView
          message="系统日志统计加载失败"
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
          </div>
        </div>
      ) : null}

      <div className="panel">
        <h3>近期登录日志</h3>
        {loginLogsError ? (
          <ErrorStateView
            message="登录日志加载失败"
            onRetry={refetchLoginLogs}
          />
        ) : null}
        {loginLogsLoading ? <div className="placeholder">加载中...</div> : null}
        {!loginLogsError ? (
          <DataTable columns={loginColumns} rows={loginLogRows || []} />
        ) : null}
      </div>

      <div className="panel">
        <h3>近期操作日志</h3>
        {operationLogsError ? (
          <ErrorStateView
            message="操作日志加载失败"
            onRetry={refetchOperationLogs}
          />
        ) : null}
        {operationLogsLoading ? <div className="placeholder">加载中...</div> : null}
        {!operationLogsError ? (
          <DataTable columns={operationColumns} rows={operationLogRows || []} />
        ) : null}
      </div>
    </PageLayout>
  );
}
