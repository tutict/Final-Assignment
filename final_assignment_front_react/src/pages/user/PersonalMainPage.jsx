import React from 'react';
import PageLayout from '../../components/PageLayout.jsx';
import { useAuth } from '../../auth/AuthContext.jsx';

export default function PersonalMainPage() {
  const { auth } = useAuth();
  return (
    <PageLayout title="个人主页" subtitle="账户信息总览">
      <div className="profile-card">
        <h3>{auth?.driverName || auth?.userName || '未命名用户'}</h3>
        <p>邮箱：{auth?.userEmail || '-'}</p>
        <p>角色：{auth?.userRole || 'USER'}</p>
      </div>
    </PageLayout>
  );
}
