import React from 'react';
import PageLayout from '../../components/PageLayout.jsx';
import SimpleBarChart from '../../components/SimpleBarChart.jsx';

const violationData = [
  { label: '超速', value: 120 },
  { label: '闯红灯', value: 80 },
  { label: '违停', value: 50 },
  { label: '酒驾', value: 20 },
  { label: '其他', value: 30 },
];

const paymentData = [
  { label: '已缴', value: 100 },
  { label: '未缴', value: 50 },
];

export default function TrafficViolationScreenPage() {
  return (
    <PageLayout title="交通违法概览" subtitle="图表化分析近期违法趋势">
      <div className="grid-two">
        <div className="panel">
          <h3>违法类型</h3>
          <SimpleBarChart data={violationData} />
        </div>
        <div className="panel">
          <h3>缴费状态</h3>
          <SimpleBarChart data={paymentData} />
        </div>
      </div>
    </PageLayout>
  );
}
