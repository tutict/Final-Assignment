import React from 'react';
import PageLayout from '../../components/PageLayout.jsx';
import StatCard from '../../components/StatCard.jsx';

export default function UserDashboardPage() {
  return (
    <PageLayout title="用户首页" subtitle="查看违法记录与业务进度">
      <div className="stat-grid">
        <StatCard title="未处理违法" value="5" description="待处理违法记录" />
        <StatCard title="待缴罚款" value="3" description="可在线缴纳" />
        <StatCard title="处理中申诉" value="1" description="等待审核" />
        <StatCard title="车辆信息" value="2" description="已绑定车辆" />
      </div>
      <div className="panel">
        <h3>快速入口</h3>
        <p>使用左侧菜单进入违法记录、车辆管理与在线办理。</p>
      </div>
    </PageLayout>
  );
}
