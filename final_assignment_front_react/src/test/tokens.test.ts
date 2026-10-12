import { describe, expect, it } from 'vitest';
import { clearTokens, decodeJwt, getAccessToken, getRefreshToken, getTokenExp, setTokens } from '../auth/tokens';

// header.payload.sig with a base64url JSON payload — signature is never verified client-side.
function jwt(payload: Record<string, unknown>): string {
  const b64 = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  return `${b64({ alg: 'none' })}.${b64(payload)}.sig`;
}

describe('token persistence', () => {
  it('stores and clears access/refresh tokens in localStorage', () => {
    setTokens('access-1', 'refresh-1');
    expect(getAccessToken()).toBe('access-1');
    expect(getRefreshToken()).toBe('refresh-1');

    setTokens('access-2'); // refresh untouched when omitted
    expect(getAccessToken()).toBe('access-2');
    expect(getRefreshToken()).toBe('refresh-1');

    clearTokens();
    expect(getAccessToken()).toBeNull();
    expect(getRefreshToken()).toBeNull();
  });

  it('decodes JWT payloads without verifying the signature', () => {
    const payload = decodeJwt(jwt({ sub: 'ce@ce.com', role: 'ROLE_ADMIN' }));
    expect(payload).toMatchObject({ sub: 'ce@ce.com', role: 'ROLE_ADMIN' });
  });

  it('returns null for malformed tokens', () => {
    expect(decodeJwt('not-a-jwt')).toBeNull();
    expect(decodeJwt('a.b')).toBeNull();
  });

  it('converts the exp claim from seconds to a millisecond timestamp', () => {
    expect(getTokenExp(jwt({ exp: 1700000000 }))).toBe(1700000000 * 1000);
    expect(getTokenExp(jwt({ noExp: true }))).toBeNull();
  });
});
