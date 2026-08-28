import { useState } from 'react';
import PageLayout from '../../components/PageLayout';
import { trafficMapPoints, type TrafficMapPoint } from '../../config/trafficMapPoints';

/**
 * 违法地图页面：以静态网格 + 列表方式展示哈尔滨交通服务点。
 *
 * 不引入 react-leaflet 等重依赖；后端如需真实地图，可在地图 SDK 接入后替换本实现。
 * 对齐 Flutter `map.dart`：4 个服务点 + 距离/选择交互。
 */
const HARBIN_CENTER: TrafficMapPoint = trafficMapPoints[0];

function distanceLabel(point: TrafficMapPoint): string {
  const latDiff = (point.lat - HARBIN_CENTER.lat) * 111;
  const lngDiff = (point.lng - HARBIN_CENTER.lng) * 111 * Math.cos((point.lat * Math.PI) / 180);
  const km = Math.sqrt(latDiff * latDiff + lngDiff * lngDiff);
  return km < 1 ? `${(km * 1000).toFixed(0)} 米` : `${km.toFixed(2)} 公里`;
}

export default function MapPage() {
  const [selected, setSelected] = useState<TrafficMapPoint>(trafficMapPoints[0]);

  return (
    <PageLayout title="违法地图" subtitle="重点区域 · 热点分布 · 实时监测">
      <div className="map-layout">
        <div className="map-canvas">
          <div className="map-grid" />
          {trafficMapPoints.map((point) => {
            const x = ((point.lng - 126.55) / (126.65 - 126.55)) * 100;
            const y = (1 - (point.lat - 45.68) / (45.83 - 45.68)) * 100;
            const isActive = selected.title === point.title;
            return (
              <button
                key={point.title}
                type="button"
                className={`map-pin ${isActive ? 'is-active' : ''}`}
                style={{
                  left: `${Math.min(Math.max(x, 2), 96)}%`,
                  top: `${Math.min(Math.max(y, 2), 96)}%`,
                  ['--pin-color' as string]: point.color,
                }}
                title={point.title}
                onClick={() => setSelected(point)}
              >
                <span className="map-pin-dot" />
              </button>
            );
          })}
        </div>
        <div className="map-sidebar">
          <h3>哈尔滨交通服务点</h3>
          <ul className="map-list">
            {trafficMapPoints.map((point) => (
              <li
                key={point.title}
                className={selected.title === point.title ? 'is-active' : ''}
              >
                <button type="button" onClick={() => setSelected(point)}>
                  <span className="map-pin-color" style={{ background: point.color }} />
                  <div>
                    <strong>{point.title}</strong>
                    <span className="map-distance">距中心 {distanceLabel(point)}</span>
                    <p>{point.description}</p>
                  </div>
                </button>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </PageLayout>
  );
}
