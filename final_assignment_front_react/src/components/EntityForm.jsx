import React from 'react';
import { fromInputDateTime, toInputDateTime, humanizeKey } from '../utils/format';

function getInputType(type, name) {
  if (type === 'bool') return 'checkbox';
  if (type === 'int' || type === 'double') return 'number';
  if (type === 'DateTime') return 'datetime-local';
  if (name.toLowerCase().includes('email')) return 'email';
  if (name.toLowerCase().includes('password')) return 'password';
  return 'text';
}

function isMultiline(name) {
  const markers = ['description', 'remarks', 'reason', 'content', 'address', 'result', 'opinion'];
  return markers.some((marker) => name.toLowerCase().includes(marker));
}

export default function EntityForm({ fields, value, onChange, disabledFields }) {
  return (
    <div className="form-grid">
      {fields.map((field) => {
        const label = field.label || humanizeKey(field.name);
        const type = field.type || 'String';
        const inputType = getInputType(type, field.name);
        const isDisabled = field.readOnly || disabledFields?.includes(field.name);
        const rawValue = value?.[field.name];
        const renderedValue =
          inputType === 'datetime-local'
            ? toInputDateTime(rawValue)
            : inputType === 'checkbox'
              ? Boolean(rawValue)
              : rawValue ?? '';

        return (
          <label key={field.name} className="form-field">
            <span>{label}</span>
            {inputType === 'checkbox' ? (
              <input
                type="checkbox"
                checked={Boolean(renderedValue)}
                onChange={(event) => onChange(field.name, event.target.checked)}
                disabled={isDisabled}
              />
            ) : isMultiline(field.name) ? (
              <textarea
                value={renderedValue}
                onChange={(event) => onChange(field.name, event.target.value)}
                disabled={isDisabled}
                rows={3}
              />
            ) : (
              <input
                type={inputType}
                value={renderedValue}
                onChange={(event) => {
                  let nextValue;
                  if (inputType === 'datetime-local') {
                    nextValue = fromInputDateTime(event.target.value);
                  } else if (inputType === 'number') {
                    nextValue = event.target.value === '' ? null : Number(event.target.value);
                  } else {
                    nextValue = event.target.value;
                  }
                  onChange(field.name, nextValue);
                }}
                disabled={isDisabled}
              />
            )}
          </label>
        );
      })}
    </div>
  );
}

