import { describe, expect, it } from 'vitest';
import { validateEntityForm } from '../components/EntityForm';
import type { EntityField } from '../config/entityTypes';

describe('validateEntityForm', () => {
  it('flags missing required fields with the localized label', () => {
    const fields: EntityField[] = [{ name: 'plateNo', label: '车牌号', validation: { required: true } }];
    expect(validateEntityForm(fields, {})).toEqual({ plateNo: '车牌号为必填项' });
  });

  it('accepts empty optional fields', () => {
    const fields: EntityField[] = [{ name: 'remarks', validation: { required: false } }];
    expect(validateEntityForm(fields, {})).toEqual({});
  });

  it('validates patterns and stops at the first failure per field', () => {
    const fields: EntityField[] = [
      {
        name: 'ownerIdCard',
        label: '身份证号',
        validation: { required: true, pattern: /^\d{17}[\dX]$/, message: '身份证号须为 18 位' },
      },
    ];
    expect(validateEntityForm(fields, { ownerIdCard: '123' })).toEqual({ ownerIdCard: '身份证号须为 18 位' });
    expect(validateEntityForm(fields, { ownerIdCard: '110101199001010011' })).toEqual({});
  });

  it('enforces enum membership', () => {
    const fields: EntityField[] = [
      { name: 'status', label: '状态', validation: { enum: ['Active', 'Suspended'] } },
    ];
    expect(validateEntityForm(fields, { status: 'Banned' })).toEqual({ status: '状态取值无效' });
    expect(validateEntityForm(fields, { status: 'Active' })).toEqual({});
  });

  it('enforces numeric min/max bounds', () => {
    const fields: EntityField[] = [
      { name: 'deductionPoints', label: '扣分', validation: { min: 0, max: 12 } },
    ];
    expect(validateEntityForm(fields, { deductionPoints: 'abc' })).toEqual({ deductionPoints: '扣分须为数字' });
    expect(validateEntityForm(fields, { deductionPoints: 13 })).toEqual({ deductionPoints: '扣分超出范围' });
    expect(validateEntityForm(fields, { deductionPoints: 3 })).toEqual({});
  });

  it('enforces string length bounds without treating text as a number', () => {
    const fields: EntityField[] = [
      { name: 'username', label: '账号', validation: { minLength: 3, maxLength: 5, message: '账号长度须为 3~5 个字符' } },
    ];
    expect(validateEntityForm(fields, { username: 'admin' })).toEqual({});
    expect(validateEntityForm(fields, { username: 'ab' })).toEqual({ username: '账号长度须为 3~5 个字符' });
    expect(validateEntityForm(fields, { username: 'administrator' })).toEqual({ username: '账号长度须为 3~5 个字符' });
  });

  it('reports every failing field at once', () => {
    const fields: EntityField[] = [
      { name: 'a', label: 'A', validation: { required: true } },
      { name: 'b', label: 'B', validation: { min: 1 } },
    ];
    const errors = validateEntityForm(fields, { b: 0 });
    expect(Object.keys(errors)).toEqual(['a', 'b']);
  });
});
