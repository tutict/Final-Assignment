import React from 'react';
import StatusPill from '../components/StatusPill';
import { formatDateTime } from './format';
import { getValueLabel } from './valueLabels';
import { resolveFieldLabel } from '../config/fieldLabels';
import type { EntityField } from '../config/entityTypes';
import type { DataTableColumn } from '../components/DataTable';

function fieldKey(field: EntityField & { key?: string }): string {
  return field.key || field.name;
}

/** 这些字段名虽含 time，但语义是耗时/时长而非时间点，按日期渲染会得到 1970 纪元值。 */
const DURATION_KEYS = new Set(['executiontime', 'duration', 'durationms', 'elapsedtime', 'processingtime', 'timeoutms']);

function isDateField(field: EntityField & { key?: string }): boolean {
  const key = fieldKey(field)?.toLowerCase() || '';
  if (field.type) {
    return field.type === 'DateTime';
  }
  if (DURATION_KEYS.has(key)) {
    return false;
  }
  return key.includes('time') || key.includes('date');
}

function isStatusField(field: EntityField & { key?: string }): boolean {
  const key = fieldKey(field)?.toLowerCase() || '';
  return key.includes('status');
}

function defaultRenderer(field: EntityField & { key?: string }) {
  const key = fieldKey(field);
  return (row: Record<string, unknown>): React.ReactNode => {
    const value = row?.[key];
    if (isDateField(field)) {
      return formatDateTime(value);
    }
    if (isStatusField(field)) {
      return React.createElement(StatusPill, { value, field: key });
    }
    return getValueLabel(key, value);
  };
}

export type ColumnOverride =
  | ((row: Record<string, unknown>) => React.ReactNode)
  | { label?: string; render?: (row: Record<string, unknown>) => React.ReactNode };

export function buildColumns(
  fields: Array<EntityField & { key?: string }>,
  overrides: Record<string, ColumnOverride> = {}
): DataTableColumn[] {
  return fields.map((field) => {
    const key = fieldKey(field);
    const override = overrides[key];
    const overrideConfig = typeof override === 'object' ? override : {};

    return {
      key,
      label: overrideConfig.label || resolveFieldLabel(key, field.label),
      render:
        typeof override === 'function'
          ? override
          : overrideConfig.render || defaultRenderer(field),
    };
  });
}
