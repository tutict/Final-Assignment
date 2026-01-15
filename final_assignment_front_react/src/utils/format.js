import dayjs from 'dayjs';

export function formatDateTime(value) {
  if (!value) return '';
  const parsed = dayjs(value);
  return parsed.isValid() ? parsed.format('YYYY-MM-DD HH:mm') : String(value);
}

export function formatDate(value) {
  if (!value) return '';
  const parsed = dayjs(value);
  return parsed.isValid() ? parsed.format('YYYY-MM-DD') : String(value);
}

export function toInputDateTime(value) {
  if (!value) return '';
  const parsed = dayjs(value);
  return parsed.isValid() ? parsed.format('YYYY-MM-DDTHH:mm') : '';
}

export function fromInputDateTime(value) {
  if (!value) return null;
  const parsed = dayjs(value);
  return parsed.isValid() ? parsed.toISOString() : value;
}

export function humanizeKey(key) {
  if (!key) return '';
  const withSpaces = key.replace(/([a-z0-9])([A-Z])/g, '$1 $2');
  return withSpaces.replace(/_/g, ' ').replace(/^./, (c) => c.toUpperCase());
}

export function normalizeText(value) {
  if (value === null || value === undefined) return '';
  return String(value).toLowerCase();
}

