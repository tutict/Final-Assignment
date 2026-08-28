import { API_PATHS } from '../constants/apiPaths';
import { api } from './client';

export interface LoginPayload {
  username: string;
  password: string;
}

export interface LoginResult {
  jwtToken?: string;
  message?: string;
  error?: string;
  user?: {
    name?: string;
    realName?: string;
    email?: string;
    userId?: number | string;
    driverName?: string;
    [key: string]: unknown;
  };
  [key: string]: unknown;
}

export interface RegisterPayload {
  username: string;
  password: string;
  role?: string;
  idempotencyKey?: string;
}

export interface RegisterResult {
  status?: string;
  error?: string;
  [key: string]: unknown;
}

export async function login(payload: LoginPayload): Promise<LoginResult> {
  const response = await api.post<LoginResult>(API_PATHS.AUTH_LOGIN, payload);
  return response.data;
}

export async function register(payload: RegisterPayload): Promise<RegisterResult> {
  const response = await api.post<RegisterResult>(API_PATHS.AUTH_REGISTER, payload);
  return response.data;
}

export async function getAllUsers<T = unknown[]>(): Promise<T> {
  const response = await api.get<T>(API_PATHS.AUTH_USERS);
  return response.data;
}

export interface RefreshResult {
  jwtToken?: string;
  refreshToken?: string;
  [key: string]: unknown;
}

/** 用 refresh token 换取新的访问令牌。后端 PQC 鉴权支持 /api/auth/refresh。 */
export async function refreshAccessToken(refreshToken: string): Promise<RefreshResult> {
  const response = await api.post<RefreshResult>(API_PATHS.AUTH_REFRESH, { refreshToken });
  return response.data;
}

/** 通知后端撤销 refresh token（服务端吊销 + 黑名单）。失败不阻塞本地登出。 */
export async function logoutRefresh(refreshToken: string | null): Promise<void> {
  if (!refreshToken) return;
  try {
    await api.post(API_PATHS.AUTH_LOGOUT, { refreshToken });
  } catch {
    /* 登出失败不阻塞本地清理 */
  }
}
