/**
 * 日志检索筛选条，对齐 Flutter SearchFilterBar。
 * 支持字段下拉（搜索类型）+ 文本输入 + 日期范围（time-range 时显示）。
 * time-range 时禁用文本输入，仅用起止日期。
 */
import type { ReactNode } from 'react';

export interface SearchTypeOption {
  value: string;
  label: string;
  hint: string;
}

interface SearchFilterBarProps {
  options: SearchTypeOption[];
  selectedType: string;
  onTypeChange: (type: string) => void;
  textValue: string;
  onTextChange: (value: string) => void;
  startDate: string;
  endDate: string;
  onStartDateChange: (value: string) => void;
  onEndDateChange: (value: string) => void;
  onSearch: () => void;
  onClear: () => void;
  actions?: ReactNode;
}

const TIME_RANGE = 'time-range';

export default function SearchFilterBar({
  options,
  selectedType,
  onTypeChange,
  textValue,
  onTextChange,
  startDate,
  endDate,
  onStartDateChange,
  onEndDateChange,
  onSearch,
  onClear,
  actions,
}: SearchFilterBarProps) {
  const isTimeRange = selectedType === TIME_RANGE;
  const hasFilter = Boolean(textValue.trim()) || Boolean(startDate) || Boolean(endDate);

  return (
    <div className="search-filter-bar">
      <select
        value={selectedType}
        onChange={(event) => onTypeChange(event.target.value)}
        aria-label="检索字段"
      >
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>

      {isTimeRange ? (
        <div className="search-date-range">
          <input
            type="date"
            value={startDate}
            onChange={(event) => onStartDateChange(event.target.value)}
            aria-label="开始日期"
          />
          <span>至</span>
          <input
            type="date"
            value={endDate}
            onChange={(event) => onEndDateChange(event.target.value)}
            aria-label="结束日期"
          />
        </div>
      ) : (
        <input
          type="text"
          value={textValue}
          placeholder={options.find((o) => o.value === selectedType)?.hint || '输入检索值'}
          onChange={(event) => onTextChange(event.target.value)}
          onKeyDown={(event) => {
            if (event.key === 'Enter') onSearch();
          }}
        />
      )}

      <button type="button" className="primary" onClick={onSearch}>
        检索
      </button>
      <button type="button" className="ghost" onClick={onClear} disabled={!hasFilter}>
        清空
      </button>
      {actions ? <div className="search-filter-actions">{actions}</div> : null}
    </div>
  );
}
