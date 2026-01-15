import React from 'react';
import { useParams } from 'react-router-dom';
import PageLayout from '../../components/PageLayout.jsx';

export default function ProgressDetailPage() {
  const { id } = useParams();
  return (
    <PageLayout title="进度详情" subtitle={`记录编号：${id || '-'}`}>
      <div className="placeholder">请在此展示进度详情与流程节点。</div>
    </PageLayout>
  );
}
