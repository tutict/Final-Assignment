import React from 'react';
import PageLayout from '../../components/PageLayout.jsx';

export default function PlaceholderPage({
  title = '功能建设中',
  description = '该功能正在开发中，敬请期待。',
  children,
}) {
  return (
    <PageLayout title={title} subtitle={description}>
      <div className="placeholder">
        {children || '页面正在建设中，已预留路由和结构。'}
      </div>
    </PageLayout>
  );
}

