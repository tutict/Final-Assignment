/**
 * 环形图（饼图），对齐 Flutter OffensePieChart。
 * 纯 SVG donut + 中心总数。
 */
interface PieSlice {
  label: string;
  value: number;
  color?: string;
}

interface PieChartProps {
  data: PieSlice[];
  centerLabel?: string;
}

const DEFAULT_COLORS = [
  '#0c7c79',
  '#e67e22',
  '#2e8b57',
  '#c0392b',
  '#2f80ed',
  '#8e44ad',
  '#f6b93b',
];

function polarToCartesian(cx: number, cy: number, r: number, angleDeg: number) {
  const rad = ((angleDeg - 90) * Math.PI) / 180;
  return { x: cx + r * Math.cos(rad), y: cy + r * Math.sin(rad) };
}

function arcPath(cx: number, cy: number, rOuter: number, rInner: number, start: number, end: number) {
  const startOuter = polarToCartesian(cx, cy, rOuter, end);
  const endOuter = polarToCartesian(cx, cy, rOuter, start);
  const startInner = polarToCartesian(cx, cy, rInner, end);
  const endInner = polarToCartesian(cx, cy, rInner, start);
  const largeArc = end - start <= 180 ? 0 : 1;
  return [
    `M ${startOuter.x} ${startOuter.y}`,
    `A ${rOuter} ${rOuter} 0 ${largeArc} 0 ${endOuter.x} ${endOuter.y}`,
    `L ${endInner.x} ${endInner.y}`,
    `A ${rInner} ${rInner} 0 ${largeArc} 1 ${startInner.x} ${startInner.y}`,
    'Z',
  ].join(' ');
}

export default function PieChart({ data, centerLabel = '总数' }: PieChartProps) {
  const total = data.reduce((sum, item) => sum + item.value, 0);
  if (total === 0) {
    return <div className="placeholder">暂无数据</div>;
  }
  const cx = 100;
  const cy = 100;
  const rOuter = 90;
  const rInner = 56;
  let angle = 0;
  const slices = data.map((item, index) => {
    const start = angle;
    const span = (item.value / total) * 360;
    angle += span;
    const color = item.color || DEFAULT_COLORS[index % DEFAULT_COLORS.length];
    return { ...item, path: arcPath(cx, cy, rOuter, rInner, start, start + span), color, percent: Math.round((item.value / total) * 100) };
  });

  return (
    <div className="pie-chart-wrap">
      <svg viewBox="0 0 200 200" className="pie-chart">
        {slices.map((slice) => (
          <path key={slice.label} d={slice.path} fill={slice.color}>
            <title>{`${slice.label}: ${slice.value} (${slice.percent}%)`}</title>
          </path>
        ))}
        <text x="100" y="96" textAnchor="middle" className="pie-center-label">{centerLabel}</text>
        <text x="100" y="116" textAnchor="middle" className="pie-center-value">{total}</text>
      </svg>
      <div className="pie-legend">
        {slices.map((slice) => (
          <div key={slice.label} className="legend-item">
            <span className="legend-swatch" style={{ background: slice.color }} />
            <span className="legend-label">{slice.label}</span>
            <span className="legend-value">{slice.value}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
