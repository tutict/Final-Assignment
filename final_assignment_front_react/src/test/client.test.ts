import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { AxiosError, type AxiosAdapter, type InternalAxiosRequestConfig } from 'axios';
import {
  api,
  setAuthCallbacks,
  setAuthToken,
  setRefreshHook,
} from '../api/client';
import { setTokens } from '../auth/tokens';

const originalAdapter = api.defaults.adapter;

function scriptedAdapter(
  handle: (
    config: InternalAxiosRequestConfig,
    attempt: number
  ) => { status: number; data?: unknown }
): AxiosAdapter {
  let attempt = 0;
  return async (config) => {
    attempt += 1;
    const result = handle(config as InternalAxiosRequestConfig, attempt);
    const response = {
      data: result.data ?? null,
      status: result.status,
      statusText: '',
      headers: {},
      config,
    };
    if (result.status >= 400) {
      throw new AxiosError(
        'Request failed',
        String(result.status),
        config as InternalAxiosRequestConfig,
        undefined,
        response
      );
    }
    return response;
  };
}

describe('auth response interceptor', () => {
  beforeEach(() => {
    localStorage.clear();
    setTokens('old-access', 'old-refresh');
    setAuthToken('old-access');
  });

  afterEach(() => {
    setAuthCallbacks();
    setRefreshHook(null);
    setAuthToken(null);
    api.defaults.adapter = originalAdapter;
  });

  it('keeps the session when the refresh attempt fails transiently', async () => {
    const onLogout = vi.fn();
    setAuthCallbacks({ onLogout });
    setRefreshHook(async () => 'transientFailure');
    api.defaults.adapter = scriptedAdapter(() => ({ status: 401 }));

    await expect(api.get('/probe')).rejects.toMatchObject({
      isTransientAuthFailure: true,
    });

    expect(localStorage.getItem('authToken')).toBe('old-access');
    expect(localStorage.getItem('refreshToken')).toBe('old-refresh');
    expect(onLogout).not.toHaveBeenCalled();
  });

  it('retries with the refreshed token and uses it for later requests', async () => {
    setRefreshHook(async () => {
      setTokens('new-access', 'new-refresh');
      return 'success';
    });
    api.defaults.adapter = scriptedAdapter((config, attempt) => {
      if (attempt === 1) return { status: 401 };
      return {
        status: 200,
        data: { ok: true, authorization: config.headers?.Authorization },
      };
    });

    const retried = await api.get('/probe');
    expect(retried.data.ok).toBe(true);
    expect(retried.data.authorization).toBe('Bearer new-access');

    const later = await api.get('/probe');
    expect(later.data.authorization).toBe('Bearer new-access');
  });

  it('clears the session and redirects only when the refresh is rejected', async () => {
    const onLogout = vi.fn();
    const onNavigate = vi.fn();
    setAuthCallbacks({ onLogout, onNavigate });
    setRefreshHook(async () => 'rejected');
    api.defaults.adapter = scriptedAdapter(() => ({ status: 401 }));

    await expect(api.get('/probe')).rejects.toBeTruthy();

    expect(localStorage.getItem('authToken')).toBeNull();
    expect(localStorage.getItem('refreshToken')).toBeNull();
    expect(onLogout).toHaveBeenCalled();
    expect(onNavigate).toHaveBeenCalledWith('/login');
  });
});
