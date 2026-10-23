import dayjs from 'dayjs';

export function formatDateTime(value: unknown): string {
  if (!value) return '';
  const parsed = dayjs(value as string);
  return parsed.isValid() ? parsed.format('YYYY-MM-DD HH:mm') : String(value);
}

export function formatDate(value: unknown): string {
  if (!value) return '';
  const parsed = dayjs(value as string);
  return parsed.isValid() ? parsed.format('YYYY-MM-DD') : String(value);
}

export function toInputDateTime(value: unknown): string {
  if (!value) return '';
  const parsed = dayjs(value as string);
  return parsed.isValid() ? parsed.format('YYYY-MM-DDTHH:mm') : '';
}

/**
 * 后端 LocalDateTime 字段按"本地墙钟时间"解释，不接受时区后缀。
 * `toISOString()` 会转成 UTC（如本地 14:30 变成 06:30Z），在 UTC 容器里
 * 再被当作本地时间写库，导致整体偏移，因此统一输出无时区后缀的本地时间。
 */
export function toLocalIsoDateTime(value: unknown): string {
  if (!value) return '';
  const parsed = dayjs(value as string);
  return parsed.isValid() ? parsed.format('YYYY-MM-DDTHH:mm:ss') : String(value);
}

export function nowLocalIso(): string {
  return dayjs().format('YYYY-MM-DDTHH:mm:ss');
}

/** `YYYY-MM-DD` 日期选择的当天 00:00:00（本地墙钟，无时区后缀）。 */
export function toLocalDateStart(date: string): string {
  return date ? `${date}T00:00:00` : '';
}

/** `YYYY-MM-DD` 日期选择的当天 23:59:59（后端区间为闭区间）。 */
export function toLocalDateEnd(date: string): string {
  return date ? `${date}T23:59:59` : '';
}

export function fromInputDateTime(value: string): string | null {
  if (!value) return null;
  const parsed = dayjs(value);
  return parsed.isValid() ? parsed.format('YYYY-MM-DDTHH:mm:ss') : value;
}

export function humanizeKey(key: string | undefined): string {
  if (!key) return '';
  const withSpaces = key.replace(/([a-z0-9])([A-Z])/g, '$1 $2');
  return withSpaces.replace(/_/g, ' ').replace(/^./, (c) => c.toUpperCase());
}

export function normalizeText(value: unknown): string {
  if (value === null || value === undefined) return '';
  return String(value).toLowerCase();
}
