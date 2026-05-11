import React from 'react';
import StatusPill from '../components/StatusPill.jsx';
import { formatDateTime, humanizeKey } from './format.js';

function fieldKey(field) {
  return field.key || field.name;
}

function isDateField(field) {
  const key = fieldKey(field)?.toLowerCase() || '';
  return field.type === 'DateTime' || key.includes('time') || key.includes('date');
}

function isStatusField(field) {
  const key = fieldKey(field)?.toLowerCase() || '';
  return key.includes('status');
}

function defaultRenderer(field) {
  const key = fieldKey(field);
  return (row) => {
    const value = row?.[key];
    if (isDateField(field)) {
      return formatDateTime(value);
    }
    if (isStatusField(field)) {
      return React.createElement(StatusPill, { value });
    }
    return value ?? '';
  };
}

export function buildColumns(fields, overrides = {}) {
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
