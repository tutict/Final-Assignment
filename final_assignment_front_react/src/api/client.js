import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8081';

let logoutCallback = null;
let navigateCallback = null;

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json; charset=utf-8',
  },
  timeout: 15000,
});

export function setAuthCallbacks({ onLogout, onNavigate } = {}) {
  logoutCallback = typeof onLogout === 'function' ? onLogout : null;
  navigateCallback = typeof onNavigate === 'function' ? onNavigate : null;
}

export function clearStoredAuth() {
  localStorage.removeItem('authToken');
  localStorage.removeItem('userRole');
  localStorage.removeItem('userName');
  localStorage.removeItem('userEmail');
  localStorage.removeItem('driverName');
  localStorage.removeItem('userId');
  localStorage.removeItem('token');
  localStorage.removeItem('user');
}

export function setAuthToken(token) {
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

api.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error?.response?.status;

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

export function generateIdempotencyKey() {
  if (crypto?.randomUUID) {
    return crypto.randomUUID();
  }
  return `${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

export { api };
