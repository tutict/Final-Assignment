/**
 * 单次刷新（single-flight）的访问令牌续期器。
 *
 * 对齐 Flutter `AuthService.refreshJwtToken()`：
 * - 多个并发请求遇到 401 时只发一次 /api/auth/refresh；
 * - 按结果分类：success（拿到新令牌）/ rejected（refresh token 失效）/ transientFailure（网络/5xx，可重试）；
 * - 成功后回写新令牌，失败时清空本地令牌。
 */
import { refreshAccessToken, type RefreshPayload } from '../api/auth';
import { unwrapPayload } from '../api/entities';
import {
  clearTokens,
  getAccessToken,
  getRefreshToken,
  setTokens,
} from './tokens';

export type RefreshOutcome = 'success' | 'rejected' | 'transientFailure';

let inflight: Promise<RefreshOutcome> | null = null;

type TokenRefreshedListener = (accessToken: string) => void;
const tokenRefreshedListeners = new Set<TokenRefreshedListener>();

/** 订阅刷新成功后的新访问令牌；React 状态与 WebSocket 依赖它保持同步。 */
export function onAccessTokenRefreshed(listener: TokenRefreshedListener): () => void {
  tokenRefreshedListeners.add(listener);
  return () => {
    tokenRefreshedListeners.delete(listener);
  };
}

function notifyAccessTokenRefreshed(accessToken: string): void {
  tokenRefreshedListeners.forEach((listener) => {
    try {
      listener(accessToken);
    } catch {
      /* 订阅方异常不影响刷新结果 */
    }
  });
}

export async function refreshSession(): Promise<RefreshOutcome> {
  if (inflight) return inflight;

  const refreshToken = getRefreshToken();
  if (!refreshToken) {
    clearTokens();
    return 'rejected';
  }

  inflight = (async () => {
    try {
      // 后端把令牌放在 ApiResponse 的 data 里，裸对象只作兼容。
      const payload = unwrapPayload<RefreshPayload>(await refreshAccessToken(refreshToken));
      const nextAccess = payload?.accessToken || payload?.jwtToken || payload?.token;
      const nextRefresh = payload?.refreshToken || refreshToken;
      if (!nextAccess) {
        clearTokens();
        return 'rejected';
      }
      setTokens(String(nextAccess), String(nextRefresh));
      notifyAccessTokenRefreshed(String(nextAccess));
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
