import React from 'react';
import PageLayout from '../../components/PageLayout.jsx';

export default function ManagerSettingPage() {
  return (
    <PageLayout title="管理员设置" subtitle="系统安全与告警策略">
      <div className="placeholder">可在此配置管理员偏好、系统告警与审计策略。</div>
    </PageLayout>
  );
}
