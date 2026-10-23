import { describe, expect, it } from 'vitest';
import {
  formatDateTime,
  formatDate,
  fromInputDateTime,
  humanizeKey,
  normalizeText,
  nowLocalIso,
  toInputDateTime,
  toLocalDateEnd,
  toLocalDateStart,
  toLocalIsoDateTime,
} from '../utils/format';

describe('format utils', () => {
  it('formats an ISO date-time as YYYY-MM-DD HH:mm', () => {
    expect(formatDateTime('2026-10-01T08:30:00Z')).toMatch(/^2026-10-01 \d{2}:\d{2}$/);
  });

  it('returns empty strings for falsy inputs', () => {
    expect(formatDateTime(undefined)).toBe('');
    expect(formatDate(null)).toBe('');
    expect(toInputDateTime('')).toBe('');
  });

  it('passes through values dayjs cannot parse', () => {
    expect(formatDate('not-a-date')).toBe('not-a-date');
  });

  it('maps datetime-local input to a local wall-clock string without a zone', () => {
    // 后端按 LocalDateTime 解析，带 Z 会被换算时区导致写入时间偏移
    expect(fromInputDateTime('2026-10-01T08:30')).toBe('2026-10-01T08:30:00');
    expect(fromInputDateTime('2026-10-01T08:30:00')).toBe('2026-10-01T08:30:00');
  });

  it('formats arbitrary values as local wall-clock ISO without a zone suffix', () => {
    expect(toLocalIsoDateTime('2026-10-01T14:30:00')).toBe('2026-10-01T14:30:00');
    expect(toLocalIsoDateTime('')).toBe('');
    expect(toLocalIsoDateTime(undefined)).toBe('');
    expect(nowLocalIso()).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/);
  });

  it('expands date pickers to the full local day', () => {
    expect(toLocalDateStart('2026-10-01')).toBe('2026-10-01T00:00:00');
    expect(toLocalDateEnd('2026-10-01')).toBe('2026-10-01T23:59:59');
    expect(toLocalDateStart('')).toBe('');
    expect(toLocalDateEnd('')).toBe('');
  });

  it('humanizes camelCase and snake_case keys', () => {
    expect(humanizeKey('driverIdCard')).toBe('Driver Id Card');
    expect(humanizeKey('process_status')).toBe('Process status');
    expect(humanizeKey(undefined)).toBe('');
  });

  it('normalizes mixed-case text for case-insensitive search', () => {
    expect(normalizeText('DriverZhang')).toBe('driverzhang');
    expect(normalizeText(null)).toBe('');
    expect(normalizeText(undefined)).toBe('');
  });
});
