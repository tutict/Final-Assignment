/**
 * 罚款与扣分趋势图（纵向叠加），对齐 Flutter _buildLineChart。
 * 用纵向柱（罚款）+ 折线点（扣分）复合展示最近 30 天趋势。
 */
import type { TimeSeriesPoint } from '../hooks/useOffenseDashboard';

interface TrendChartProps {
  data: TimeSeriesPoint[];
}

export default function TrendChart({ data }: TrendChartProps) {
  if (data.length === 0) {
    return <div className="placeholder">暂无数据</div>;
  }
  const maxFines = Math.max(...data.map((item) => item.fines), 1);
  const maxPoints = Math.max(...data.map((item) => item.points), 1);

  // 折线点坐标（相对百分比）
  const width = 100;
  const height = 100;
  const stepX = data.length > 1 ? width / (data.length - 1) : 0;
  const linePoints = data
    .map((item, index) => {
      const x = index * stepX;
      const y = height - (item.points / maxPoints) * height;
      return `${x.toFixed(2)},${y.toFixed(2)}`;
    })
    .join(' ');

  return (
    <div className="trend-chart">
      <div className="trend-bars">
        {data.map((item) => (
          <div
            key={item.day}
            className="trend-bar"
            style={{ height: `${(item.fines / maxFines) * 100}%` }}
            title={`${item.label}：罚款 ${item.fines} 元`}
          />
        ))}
      </div>
      <svg className="trend-line" viewBox={`0 0 ${width} ${height}`} preserveAspectRatio="none">
        <polyline
          points={linePoints}
          fill="none"
          stroke="var(--accent-strong)"
          strokeWidth="1.5"
          vectorEffect="non-scaling-stroke"
        />
      </svg>
      <div className="trend-axis">
        {data
          .filter((_, index) => index % Math.max(1, Math.floor(data.length / 6)) === 0)
          .map((item) => (
            <span key={item.day}>{item.label}</span>
          ))}
      </div>
      <div className="trend-legend">
        <span className="legend-item"><span className="legend-swatch bar" /> 罚款金额</span>
        <span className="legend-item"><span className="legend-swatch line" /> 扣分</span>
      </div>
    </div>
  );
}
