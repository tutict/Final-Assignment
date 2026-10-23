import { afterEach, describe, expect, it, vi } from 'vitest';
import { listAllPages, unwrapList, unwrapPayload } from '../api/entities';
import { api } from '../api/client';

// entities.ts imports the axios singleton at module scope; the tests below only
// exercise the pure unwrapping helpers, so no network calls can happen.
import { generateIdempotencyKey, setAuthCallbacks, setRefreshHook } from '../api/client';

afterEach(() => {
  vi.restoreAllMocks();
});

describe('backend envelope unwrapping', () => {
  it('unwraps { data: { content: [...] } } page envelopes to the bare array', () => {
    const rows = unwrapList({ data: { content: [{ id: 1 }, { id: 2 }] } });
    expect(rows).toEqual([{ id: 1 }, { id: 2 }]);
  });

  it('keeps plain arrays as-is', () => {
    expect(unwrapList([{ a: 1 }])).toEqual([{ a: 1 }]);
  });

  it('falls back to an empty array for unrecognized shapes', () => {
    expect(unwrapList({ data: { noContent: true } })).toEqual([]);
    expect(unwrapList(null)).toEqual([]);
  });

  it('unwrapPayload returns the inner data object when present', () => {
    expect(unwrapPayload({ data: { id: 7 } })).toEqual({ id: 7 });
    expect(unwrapPayload({ id: 7 })).toEqual({ id: 7 });
  });
});

describe('listAllPages', () => {
  const rows = Array.from({ length: 45 }, (_, index) => ({ id: index }));

  it('keeps requesting pages until the server total is collected', async () => {
    const getSpy = vi.spyOn(api, 'get');
    // 默认分页只回 20 条
    getSpy.mockResolvedValueOnce({
      data: { content: rows.slice(0, 20), total: rows.length, page: 0, size: 20 },
    } as never);
    // 按 100/页重取第一页
    getSpy.mockResolvedValueOnce({
      data: { content: rows, total: rows.length, page: 0, size: 100 },
    } as never);

    const result = await listAllPages('/api/users');

    expect(result).toHaveLength(45);
    expect(getSpy).toHaveBeenCalledTimes(2);
    expect(getSpy.mock.calls[1][1]).toMatchObject({ params: { page: 0, size: 100 } });
  });

  it('walks subsequent pages for 1-based endpoints', async () => {
    const getSpy = vi.spyOn(api, 'get');
    getSpy.mockResolvedValueOnce({
      data: { data: { content: rows.slice(0, 2), total: 4, page: 1, size: 2 } },
    } as never);
    getSpy.mockResolvedValueOnce({
      data: { data: { content: rows.slice(2, 4), total: 4, page: 2, size: 2 } },
    } as never);

    const result = await listAllPages('/api/appeals', { page: 1, size: 2 }, { pageSize: 2 });

    expect(result).toEqual(rows.slice(0, 4));
    expect(getSpy.mock.calls[1][1]).toMatchObject({ params: { page: 2, size: 2 } });
  });

  it('returns bare arrays untouched without extra requests', async () => {
    const getSpy = vi.spyOn(api, 'get').mockResolvedValueOnce({ data: rows } as never);

    const result = await listAllPages('/api/logs/login');

    expect(result).toHaveLength(45);
    expect(getSpy).toHaveBeenCalledTimes(1);
  });
});

describe('idempotency keys', () => {
  it('generates unique keys', () => {
    const a = generateIdempotencyKey();
    const b = generateIdempotencyKey();
    expect(a).not.toBe(b);
    expect(a.length).toBeGreaterThan(0);
  });
});

describe('auth callback wiring', () => {
  it('accepts hook registration without throwing (module-level wiring contract)', () => {
    const onLogout = vi.fn();
    setAuthCallbacks({ onLogout, onNavigate: () => undefined });
    setRefreshHook(async () => 'rejected');
    // Reset to inert so other test files are not affected by module state.
    setAuthCallbacks();
    setRefreshHook(null);
    expect(true).toBe(true);
  });
});
