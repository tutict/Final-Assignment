/**
 * 轻量柱状图，对齐 Flutter OffenseBarChart / 横向 LinearProgress 分布。
 * 纯 CSS 实现，不依赖第三方图表库。
 */
interface BarDatum {
  label: string;
  value: number;
}

interface SimpleBarChartProps {
  data: BarDatum[];
  height?: number;
  /** 横向条形（用于分布列表），默认为纵向柱状 */
  horizontal?: boolean;
  unit?: string;
}

function formatValue(value: number, unit?: string): string {
  if (unit) return `${value}${unit}`;
  return String(value);
}

export default function SimpleBarChart({
  data,
  height = 220,
  horizontal = false,
  unit,
}: SimpleBarChartProps) {
  if (data.length === 0) {
    return <div className="placeholder">暂无数据</div>;
  }
  const maxValue = Math.max(...data.map((item) => item.value), 1);

  if (horizontal) {
    return (
      <div className="bar-chart-horizontal">
        {data.map((item) => (
          <div key={item.label} className="bar-row">
            <span className="bar-row-label">{item.label}</span>
            <div className="bar-track">
              <div
                className="bar-fill"
                style={{ width: `${(item.value / maxValue) * 100}%` }}
                title={formatValue(item.value, unit)}
              />
            </div>
            <span className="bar-row-value">{formatValue(item.value, unit)}</span>
          </div>
        ))}
      </div>
    );
  }

  return (
    <div className="bar-chart" style={{ height }}>
      {data.map((item) => (
        <div key={item.label} className="bar-item">
          <div
            className="bar"
            style={{ height: `${(item.value / maxValue) * 100}%` }}
            title={`${item.label}: ${formatValue(item.value, unit)}`}
          />
          <span>{item.label}</span>
        </div>
      ))}
    </div>
  );
}
