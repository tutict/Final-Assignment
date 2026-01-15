import React from 'react';
import { useQuery } from '@tanstack/react-query';
import PageLayout from '../../components/PageLayout.jsx';
import DataTable from '../../components/DataTable.jsx';
import { api } from '../../api/client.js';
import { formatDateTime } from '../../utils/format.js';

async function fetchOverview() {
  const response = await api.get('/api/system/logs/overview');
  return response.data;
}

async function fetchRecentLogin() {
  const response = await api.get('/api/system/logs/login/recent', { params: { limit: 10 } });
  return response.data;
}

async function fetchRecentOperation() {
  const response = await api.get('/api/system/logs/operation/recent', { params: { limit: 10 } });
  return response.data;
}

export default function SystemLogPage() {
  const overview = useQuery({ queryKey: ['systemLogs', 'overview'], queryFn: fetchOverview });
  const loginLogs = useQuery({ queryKey: ['systemLogs', 'loginRecent'], queryFn: fetchRecentLogin });
  const operationLogs = useQuery({ queryKey: ['systemLogs', 'operationRecent'], queryFn: fetchRecentOperation });

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
        <DataTable
          columns={[
            { key: 'username', label: '用户名' },
            { key: 'loginTime', label: '登录时间', render: (row) => formatDateTime(row.loginTime) },
            { key: 'loginResult', label: '结果' },
            { key: 'loginIp', label: 'IP' },
          ]}
          rows={loginLogs.data || []}
        />
      </div>

      <div className="panel">
        <h3>近期操作日志</h3>
        <DataTable
          columns={[
            { key: 'operationType', label: '操作类型' },
            { key: 'operationModule', label: '模块' },
            { key: 'username', label: '用户' },
            { key: 'operationTime', label: '时间', render: (row) => formatDateTime(row.operationTime) },
          ]}
          rows={operationLogs.data || []}
        />
      </div>
    </PageLayout>
  );
}
