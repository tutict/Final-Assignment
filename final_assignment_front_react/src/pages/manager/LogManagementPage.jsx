import React from 'react';
import { useNavigate } from 'react-router-dom';
import PageLayout from '../../components/PageLayout.jsx';

const logPages = [
  { title: '登录日志', path: '/loginLogPage', description: '用户登录登出与失败记录' },
  { title: '操作日志', path: '/operationLogPage', description: '后台操作与审计追踪' },
  { title: '系统日志', path: '/systemLogPage', description: '系统运行与异常信息' },
];

export default function LogManagementPage() {
  const navigate = useNavigate();
  return (
    <PageLayout title="日志管理" subtitle="审计、追踪与合规报告">
      <div className="grid-three">
        {logPages.map((page) => (
          <div key={page.path} className="panel">
            <h3>{page.title}</h3>
            <p>{page.description}</p>
            <button type="button" className="primary" onClick={() => navigate(page.path)}>
              查看
            </button>
          </div>
        ))}
      </div>
    </PageLayout>
  );
}
