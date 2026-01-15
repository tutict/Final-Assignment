import React from 'react';
import PageLayout from '../../components/PageLayout.jsx';

export default function MapPage() {
  return (
    <PageLayout title="违法地图" subtitle="重点区域 · 热点分布 · 实时监测">
      <div className="map-placeholder">
        <div className="map-grid" />
        <div className="map-overlay">
          <h3>地图服务占位</h3>
          <p>请在此接入高德/百度/Mapbox 等地图 SDK。</p>
        </div>
      </div>
    </PageLayout>
  );
}
