import { describe, expect, it, vi } from 'vitest';
import { unwrapList, unwrapPayload } from '../api/entities';

// entities.ts imports the axios singleton at module scope; the tests below only
// exercise the pure unwrapping helpers, so no network calls can happen.
import { generateIdempotencyKey, setAuthCallbacks, setRefreshHook } from '../api/client';

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
