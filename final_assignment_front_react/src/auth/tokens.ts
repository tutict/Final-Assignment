/**
 * Token 持久化工具：集中管理访问令牌与刷新令牌的本地存储。
 *
 * 与 Flutter `AuthService` 对齐：登录返回 jwtToken + refreshToken，
 * 访问令牌过期前用 refreshToken 调用 /api/auth/refresh 续期，
 * 登出时调用 /api/auth/logout 在服务端吊销 refresh token。
 */

const ACCESS_KEY = 'authToken';
const REFRESH_KEY = 'refreshToken';

export function getAccessToken(): string | null {
  return localStorage.getItem(ACCESS_KEY);
}

export function getRefreshToken(): string | null {
  return localStorage.getItem(REFRESH_KEY);
}

export function setTokens(accessToken: string | null, refreshToken?: string | null): void {
  if (accessToken) {
    localStorage.setItem(ACCESS_KEY, accessToken);
  } else {
    localStorage.removeItem(ACCESS_KEY);
  }
  if (refreshToken) {
    localStorage.setItem(REFRESH_KEY, refreshToken);
  } else if (refreshToken === null) {
    localStorage.removeItem(REFRESH_KEY);
  }
}

export function clearTokens(): void {
  localStorage.removeItem(ACCESS_KEY);
  localStorage.removeItem(REFRESH_KEY);
}

/** 解析 JWT payload（不校验签名），用于读取过期时间与角色。 */
export function decodeJwt(token: string): Record<string, unknown> | null {
  try {
    const parts = token.split('.');
    if (parts.length < 2) return null;
    const payload = parts[1];
    const json = atob(payload.replace(/-/g, '+').replace(/_/g, '/'));
    // 处理 UTF-8 中文
    const decoded = decodeURIComponent(
      json
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(decoded) as Record<string, unknown>;
  } catch {
    return null;
  }
}

export function getTokenExp(token: string): number | null {
  const payload = decodeJwt(token);
  const exp = payload?.exp;
  if (typeof exp === 'number') return exp * 1000;
  return null;
}
