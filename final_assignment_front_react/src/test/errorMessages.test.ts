import { describe, expect, it } from 'vitest';
import { getErrorMessage } from '../utils/errorMessages';

const axiosError = (status?: number, data?: unknown) => ({
  response: { status, data },
});

describe('getErrorMessage', () => {
  it('maps 401 to a session-expired message', () => {
    expect(getErrorMessage(axiosError(401))).toBe('登录已过期，请重新登录');
  });

  it('maps 403 to a permission message', () => {
    expect(getErrorMessage(axiosError(403))).toBe('您没有权限执行此操作');
  });

  it('prefers joined field-level messages on 409', () => {
    const e = axiosError(409, { data: [{ message: '车牌号已被登记 ' }, { message: '' }, { message: '车架号重复' }] });
    expect(getErrorMessage(e)).toBe('车牌号已被登记；车架号重复');
  });

  it('falls back to the generic conflict hint when 409 carries only the stock constraint message', () => {
    const e = axiosError(409, { message: '数据约束冲突' });
    expect(getErrorMessage(e)).toBe('数据冲突，请检查是否重复提交');
  });

  it('maps 5xx to the server-unavailable message', () => {
    expect(getErrorMessage(axiosError(503))).toBe('服务器暂时不可用，请稍后重试');
  });

  it('surfaces the raw error message for unknown statuses', () => {
    expect(getErrorMessage({ message: 'boom' })).toBe('boom');
  });
});
