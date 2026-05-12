import React from 'react';

/**
 * @component StatCard
 * @description 指标卡片，展示标题、数值、趋势和补充说明。
 *
 * @param {{
 *   title: string,
 *   value: React.ReactNode,
 *   trend?: React.ReactNode,
 *   description?: React.ReactNode,
 * }} props - 指标名称、数值、趋势提示和说明文本。
 *
 * @notes
 * - 当前没有 unit prop。
 */
export default function StatCard({ title, value, trend, description }) {
  return (
    <div className="stat-card">
      <div className="stat-header">
        <span>{title}</span>
        {trend ? <span className="stat-trend">{trend}</span> : null}
      </div>
      <div className="stat-value">{value}</div>
      {description ? <div className="stat-description">{description}</div> : null}
    </div>
  );
}

