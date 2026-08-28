import axios, { type AxiosInstance, type InternalAxiosRequestConfig } from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8081';

type AuthCallbacks = {
  onLogout?: () => void;
  onNavigate?: (path: string) => void;
};

let logoutCallback: (() => void) | null = null;
let navigateCallback: ((path: string) => void) | null = null;

export const api: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json; charset=utf-8',
  },
  timeout: 15000,
});

export function setAuthCallbacks({ onLogout, onNavigate }: AuthCallbacks = {}): void {
  logoutCallback = typeof onLogout === 'function' ? onLogout : null;
  navigateCallback = typeof onNavigate === 'function' ? onNavigate : null;
}

export function clearStoredAuth(): void {
  localStorage.removeItem('authToken');
  localStorage.removeItem('refreshToken');
  localStorage.removeItem('userRole');
  localStorage.removeItem('userName');
  localStorage.removeItem('userEmail');
  localStorage.removeItem('driverName');
  localStorage.removeItem('userId');
  localStorage.removeItem('token');
  localStorage.removeItem('user');
}

export function setAuthToken(token: string | null): void {
  if (token) {
    api.defaults.headers.common.Authorization = `Bearer ${token}`;
  } else {
    delete api.defaults.headers.common.Authorization;
  }
}

api.interceptors.request.use((config) => {
  const stored = localStorage.getItem('authToken');
  if (stored && !config.headers.Authorization) {
    config.headers.Authorization = `Bearer ${stored}`;
  }
  return config;
});

// ---- 刷新令牌 single-flight 钩子（由 AuthContext 注入，避免循环依赖） ----
let refreshHook: (() => Promise<'success' | 'rejected' | 'transientFailure'>) | null = null;

export function setRefreshHook(
  hook: (() => Promise<'success' | 'rejected' | 'transientFailure'>) | null
): void {
  refreshHook = hook;
}

const SKIP_REFRESH = '/api/auth/refresh';

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const status = error?.response?.status;
    const original = error?.config as
      | (InternalAxiosRequestConfig & { _retry?: boolean })
      | undefined;

    // 401 时尝试一次刷新续期（对齐 Flutter AuthService），刷新端点自身的 401 不重试
    if (
      status === 401 &&
      original &&
      !original._retry &&
      refreshHook &&
      !(original.url || '').includes(SKIP_REFRESH)
    ) {
      original._retry = true;
      try {
        const outcome = await refreshHook();
        if (outcome === 'success') {
          const stored = localStorage.getItem('authToken');
          if (stored) {
            original.headers.Authorization = `Bearer ${stored}`;
          }
          return api.request(original);
        }
      } catch {
        /* 刷新失败，继续走登录重定向 */
      }
    }

    if (status === 401) {
      clearStoredAuth();
      setAuthToken(null);
      logoutCallback?.();
      navigateCallback?.('/login');
      return Promise.reject(error);
    }

    if (status === 403) {
      return Promise.reject(Object.assign(error, { isForbidden: true }));
    }

    return Promise.reject(error);
  }
);

export function generateIdempotencyKey(): string {
  if (crypto?.randomUUID) {
    return crypto.randomUUID();
  }
  return `${Date.now()}-${Math.random().toString(16).slice(2)}`;
}
