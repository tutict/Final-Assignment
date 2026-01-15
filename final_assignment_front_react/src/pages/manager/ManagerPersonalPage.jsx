import React from 'react';
import PageLayout from '../../components/PageLayout.jsx';
import { useAuth } from '../../auth/AuthContext.jsx';

export default function ManagerPersonalPage() {
  const { auth } = useAuth();
  return (
    <PageLayout title="管理员信息" subtitle="账户与权限概览">
      <div className="profile-card">
        <h3>{auth?.userName || '管理员'}</h3>
        <p>邮箱：{auth?.userEmail || '-'}</p>
        <p>角色：{auth?.userRole || 'ADMIN'}</p>
      </div>
    </PageLayout>
  );
}
