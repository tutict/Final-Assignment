import React from 'react';

/**
 * @component SimpleBarChart
 * @description 轻量柱状图组件，基于 label/value 数组渲染高度比例条形图。
 *
 * @param {{
 *   data: Array<{ label: string, value: number }>,
 *   height?: number,
 * }} props - 图表数据和容器高度。
 *
 * @notes
 * - height 默认 220px。
 * - data 项必须提供 label 和 value，当前不支持 xKey/yKey 自定义字段名。
 */
export default function SimpleBarChart({ data, height = 220 }) { // 默认图表高度（px），可通过 height prop 覆盖
  const maxValue = Math.max(...data.map((item) => item.value), 1); // 防止除零错误的最小值 fallback
  return (
    <div className="bar-chart" style={{ height }}>
      {data.map((item) => (
        <div key={item.label} className="bar-item">
          <div
            className="bar"
            // 百分比计算基数
            style={{ height: `${(item.value / maxValue) * 100}%` }}
            title={`${item.label}: ${item.value}`}
          />
          <span>{item.label}</span>
        </div>
      ))}
    </div>
  );
}

