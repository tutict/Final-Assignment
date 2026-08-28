import React from 'react';
import StatusPill from '../components/StatusPill';
import { formatDateTime, humanizeKey } from './format';
import type { EntityField } from '../config/entityTypes';
import type { DataTableColumn } from '../components/DataTable';

function fieldKey(field: EntityField & { key?: string }): string {
  return field.key || field.name;
}

function isDateField(field: EntityField & { key?: string }): boolean {
  const key = fieldKey(field)?.toLowerCase() || '';
  return field.type === 'DateTime' || key.includes('time') || key.includes('date');
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
      return React.createElement(StatusPill, { value });
    }
    return (value ?? '') as React.ReactNode;
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
      label: overrideConfig.label || field.label || humanizeKey(key),
      render:
        typeof override === 'function'
          ? override
          : overrideConfig.render || defaultRenderer(field),
    };
  });
}
