import React from 'react';
import PageLayout from '../../components/PageLayout.jsx';
import StatCard from '../../components/StatCard.jsx';
import SimpleBarChart from '../../components/SimpleBarChart.jsx';

const violationData = [
  { label: '超速', value: 120 },
  { label: '闯红灯', value: 80 },
  { label: '违停', value: 50 },
  { label: '酒驾', value: 20 },
  { label: '其他', value: 30 },
];

export default function ManagerDashboardPage() {
  return (
    <PageLayout title="管理总览" subtitle="实时掌控违法、罚款与申诉进度">
      <div className="stat-grid">
        <StatCard title="今日违法" value="15" trend="+8%" description="今日新增违法记录" />
        <StatCard title="待处理申诉" value="7" trend="-2" description="需人工审核" />
        <StatCard title="待缴罚款" value="32" trend="+6%" description="未缴金额统计" />
        <StatCard title="系统风险" value="3" trend="-1" description="异常监控" />
      </div>
      <div className="panel">
        <h3>违法类型分布</h3>
        <SimpleBarChart data={violationData} />
      </div>
    </PageLayout>
  );
}
