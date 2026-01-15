import React from 'react';
import PageLayout from '../../components/PageLayout.jsx';

export default function MainScanPage() {
  return (
    <PageLayout title="扫码服务" subtitle="事故与业务办理快速入口">
      <div className="scanner-panel">
        <div className="scanner-frame" />
        <p>请在移动端或接入摄像头组件进行扫码。</p>
      </div>
    </PageLayout>
  );
}
