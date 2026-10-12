import { describe, expect, it } from 'vitest';
import { formatDateTime, formatDate, fromInputDateTime, humanizeKey, normalizeText, toInputDateTime } from '../utils/format';

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

  it('round-trips datetime-local input values to ISO strings', () => {
    const iso = fromInputDateTime('2026-10-01T08:30');
    expect(iso).toBe(new Date(iso as string).toISOString());
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
