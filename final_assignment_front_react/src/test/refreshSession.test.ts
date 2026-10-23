import { beforeEach, describe, expect, it, vi } from 'vitest';

const refreshAccessToken = vi.fn();
vi.mock('../api/auth', () => ({
  refreshAccessToken: (...args: unknown[]) => refreshAccessToken(...args),
}));

import { getAccessToken, getRefreshToken, setTokens } from '../auth/tokens';
import {
  onAccessTokenRefreshed,
  refreshSession,
  resetRefreshState,
} from '../auth/refreshSession';

describe('refreshSession', () => {
  beforeEach(() => {
    resetRefreshState();
    refreshAccessToken.mockReset();
    localStorage.clear();
    setTokens('old-access', 'old-refresh');
  });

  it('reads the tokens from the ApiResponse envelope', async () => {
    refreshAccessToken.mockResolvedValue({
      success: true,
      data: { accessToken: 'new-access', refreshToken: 'new-refresh' },
    });

    await expect(refreshSession()).resolves.toBe('success');
    expect(getAccessToken()).toBe('new-access');
    expect(getRefreshToken()).toBe('new-refresh');
  });

  it('still accepts a bare token payload', async () => {
    refreshAccessToken.mockResolvedValue({ accessToken: 'new-access', refreshToken: 'new-refresh' });

    await expect(refreshSession()).resolves.toBe('success');
    expect(getAccessToken()).toBe('new-access');
  });

  it('keeps the stored refresh token when the response omits it', async () => {
    refreshAccessToken.mockResolvedValue({ success: true, data: { accessToken: 'new-access' } });

    await expect(refreshSession()).resolves.toBe('success');
    expect(getRefreshToken()).toBe('old-refresh');
  });

  it('rejects and clears the session when no access token comes back', async () => {
    refreshAccessToken.mockResolvedValue({ success: true, data: {} });

    await expect(refreshSession()).resolves.toBe('rejected');
    expect(getAccessToken()).toBeNull();
    expect(getRefreshToken()).toBeNull();
  });

  it('notifies subscribers with the refreshed access token', async () => {
    const listener = vi.fn();
    const unsubscribe = onAccessTokenRefreshed(listener);
    refreshAccessToken.mockResolvedValue({
      success: true,
      data: { accessToken: 'new-access', refreshToken: 'new-refresh' },
    });

    await expect(refreshSession()).resolves.toBe('success');
    expect(listener).toHaveBeenCalledWith('new-access');
    unsubscribe();
  });

  it('does not notify subscribers on transient failure', async () => {
    const listener = vi.fn();
    const unsubscribe = onAccessTokenRefreshed(listener);
    refreshAccessToken.mockRejectedValue({ response: { status: 503 } });

    await expect(refreshSession()).resolves.toBe('transientFailure');
    expect(listener).not.toHaveBeenCalled();
    expect(getAccessToken()).toBe('old-access');
    unsubscribe();
  });
});
