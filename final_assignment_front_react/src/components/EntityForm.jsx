import React from 'react';
import { fromInputDateTime, toInputDateTime, humanizeKey } from '../utils/format';

function getInputType(type, name) {
  if (type === 'select') return 'select';
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

export function validateEntityForm(fields, values = {}) {
  const errors = {};

  fields.forEach((field) => {
    const validation = field.validation;
    if (!validation) return;

    const label = field.label || humanizeKey(field.name);
    const value = values?.[field.name];
    const isEmpty = value === undefined || value === null || value === '';

    if (validation.required && isEmpty) {
      errors[field.name] = `${label}为必填项`;
      return;
    }

    if (isEmpty) return;

    if (validation.pattern) {
      validation.pattern.lastIndex = 0;
      if (!validation.pattern.test(String(value))) {
        errors[field.name] = validation.message;
        return;
      }
    }

    if (validation.enum) {
      const allowedValues = validation.enum.map(String);
      if (!allowedValues.includes(String(value))) {
        errors[field.name] = validation.message;
        return;
      }
    }

    if (validation.min !== undefined || validation.max !== undefined) {
      const numericValue = Number(value);
      if (Number.isNaN(numericValue)) {
        errors[field.name] = validation.message;
        return;
      }

      if (validation.min !== undefined && numericValue < validation.min) {
        errors[field.name] = validation.message;
        return;
      }

      if (validation.max !== undefined && numericValue > validation.max) {
        errors[field.name] = validation.message;
      }
    }
  });

  return errors;
}

/**
 * @component EntityForm
 * @description 根据实体字段配置渲染编辑表单，负责字段输入类型推断、只读控制和表单值回写。
 *
 * @param {{
 *   fields: Array<{ name: string, label?: string, type?: string, readOnly?: boolean, validation?: object }>,
 *   value: Record<string, unknown>,
 *   onChange: (name: string, value: unknown) => void,
 *   disabledFields?: Array<string>,
 *   fieldErrors?: Record<string, string>,
 * }} props - 表单字段配置、当前值和变更回调。
 *
 * @notes
 * - 当前组件使用 value/onChange/disabledFields，不支持 initialValues/onSubmit/isLoading/mode。
 * - 字段输入类型由 field.type 和 field.name 推断。
 */
export default function EntityForm({ fields, value, onChange, disabledFields, fieldErrors = {} }) {
  return (
    <div className="form-grid">
      {fields.map((field) => {
        const label = field.label || humanizeKey(field.name);
        const type = field.type || 'String';
        const inputType = getInputType(type, field.name);
        const isDisabled = field.readOnly || disabledFields?.includes(field.name);
        const options = field.options || field.validation?.enum || [];
        const isSelect = inputType === 'select' || options.length > 0;
        const error = fieldErrors[field.name];
        const errorId = `${field.name}-error`;
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
                aria-invalid={Boolean(error)}
                aria-describedby={error ? errorId : undefined}
              />
            ) : isSelect ? (
              <select
                value={renderedValue}
                onChange={(event) => onChange(field.name, event.target.value)}
                disabled={isDisabled}
                aria-invalid={Boolean(error)}
                aria-describedby={error ? errorId : undefined}
              >
                <option value="">请选择</option>
                {options.map((option) => (
                  <option key={String(option)} value={option}>
                    {String(option)}
                  </option>
                ))}
              </select>
            ) : isMultiline(field.name) ? (
              <textarea
                value={renderedValue}
                onChange={(event) => onChange(field.name, event.target.value)}
                disabled={isDisabled}
                rows={3}
                aria-invalid={Boolean(error)}
                aria-describedby={error ? errorId : undefined}
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
                aria-invalid={Boolean(error)}
                aria-describedby={error ? errorId : undefined}
              />
            )}
            {error ? (
              <small id={errorId} className="field-error">
                {error}
              </small>
            ) : null}
          </label>
        );
      })}
    </div>
  );
}

