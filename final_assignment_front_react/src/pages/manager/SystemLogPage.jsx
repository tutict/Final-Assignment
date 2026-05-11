import React, { useMemo } from 'react';
import PageLayout from '../../components/PageLayout.jsx';
import DataTable from '../../components/DataTable.jsx';
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

  return (
    <PageLayout title="系统日志" subtitle="系统运行概览与近期审计">
      <div className="stat-grid">
        <div className="stat-card">
          <div className="stat-header">登录日志</div>
          <div className="stat-value">{overview.data?.loginLogCount ?? '-'}</div>
        </div>
        <div className="stat-card">
          <div className="stat-header">操作日志</div>
          <div className="stat-value">{overview.data?.operationLogCount ?? '-'}</div>
        </div>
        <div className="stat-card">
          <div className="stat-header">请求历史</div>
          <div className="stat-value">{overview.data?.requestHistoryCount ?? '-'}</div>
        </div>
      </div>

      <div className="panel">
        <h3>近期登录日志</h3>
        <DataTable columns={loginColumns} rows={loginLogs.data || []} />
      </div>

      <div className="panel">
        <h3>近期操作日志</h3>
        <DataTable columns={operationColumns} rows={operationLogs.data || []} />
      </div>
    </PageLayout>
  );
}
