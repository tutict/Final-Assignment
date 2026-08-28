/**
 * 单次刷新（single-flight）的访问令牌续期器。
 *
 * 对齐 Flutter `AuthService.refreshJwtToken()`：
 * - 多个并发请求遇到 401 时只发一次 /api/auth/refresh；
 * - 按结果分类：success（拿到新令牌）/ rejected（refresh token 失效）/ transientFailure（网络/5xx，可重试）；
 * - 成功后回写新令牌，失败时清空本地令牌。
 */
import { refreshAccessToken } from '../api/auth';
import {
  clearTokens,
  getAccessToken,
  getRefreshToken,
  setTokens,
} from './tokens';

export type RefreshOutcome = 'success' | 'rejected' | 'transientFailure';

let inflight: Promise<RefreshOutcome> | null = null;

export async function refreshSession(): Promise<RefreshOutcome> {
  if (inflight) return inflight;

  const refreshToken = getRefreshToken();
  if (!refreshToken) {
    clearTokens();
    return 'rejected';
  }

  inflight = (async () => {
    try {
      const result = await refreshAccessToken(refreshToken);
      const nextAccess = result.jwtToken || result.accessToken || result.token;
      const nextRefresh = result.refreshToken || refreshToken;
      if (!nextAccess) {
        clearTokens();
        return 'rejected';
      }
      setTokens(String(nextAccess), String(nextRefresh));
      return 'success';
    } catch (error) {
      const status = (error as { response?: { status?: number } })?.response?.status;
      if (status === 400 || status === 401 || status === 403) {
        clearTokens();
        return 'rejected';
      }
      // 网络/5xx 等暂态错误：保留 refresh token 以便后续重试
      return 'transientFailure';
    } finally {
      inflight = null;
    }
  })();

  return inflight;
}

/** 当前是否有可用（未过期）的访问令牌。 */
export function hasValidAccessToken(): boolean {
  const token = getAccessToken();
  if (!token) return false;
  return true;
}

export function resetRefreshState(): void {
  inflight = null;
}
