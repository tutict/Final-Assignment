import React from 'react';

export default function SimpleBarChart({ data, height = 220 }) {
  const maxValue = Math.max(...data.map((item) => item.value), 1);
  return (
    <div className="bar-chart" style={{ height }}>
      {data.map((item) => (
        <div key={item.label} className="bar-item">
          <div
            className="bar"
            style={{ height: `${(item.value / maxValue) * 100}%` }}
            title={`${item.label}: ${item.value}`}
          />
          <span>{item.label}</span>
        </div>
      ))}
    </div>
  );
}

