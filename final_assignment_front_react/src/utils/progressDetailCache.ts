import type { ProgressItem } from '../api/progress';

const storageKey = (id: number) => `progress-detail:${id}`;

export function rememberProgressItem(item: ProgressItem) {
  if (item.id == null || typeof sessionStorage === 'undefined') return;
  sessionStorage.setItem(storageKey(item.id), JSON.stringify(item));
}

export function readRememberedProgressItem(id: string | undefined): ProgressItem | undefined {
  if (!id || typeof sessionStorage === 'undefined') return undefined;
  const numeric = Number(id);
  if (!Number.isFinite(numeric)) return undefined;
  try {
    const raw = sessionStorage.getItem(storageKey(numeric));
    if (!raw) return undefined;
    const parsed = JSON.parse(raw) as ProgressItem;
    if (!parsed || typeof parsed !== 'object') return undefined;
    return parsed;
  } catch {
    return undefined;
  }
}
