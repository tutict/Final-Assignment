import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { jwtDecode } from 'jwt-decode';
import { useNavigate } from 'react-router-dom';
import { login as loginApi, register as registerApi, logoutRefresh } from '../api/auth';
import { getCurrentProfile } from '../api/profile';
import {
  clearStoredAuth,
  setAuthCallbacks,
  setAuthToken,
  setRefreshHook,
} from '../api/client';
import { ROLES, type RoleValue } from '../constants/roles';
import {
  clearTokens,
  getRefreshToken,
  setTokens,
} from './tokens';
import { refreshSession } from './refreshSession';

export interface AuthState {
  token: string;
  roles: string[];
  userRole: string;
  userName: string;
  userEmail: string;
  driverName: string;
  userId: string;
  driverId: string;
}

interface AuthContextValue {
  auth: AuthState | null;
  loading: boolean;
  login: (username: string, password: string) => Promise<{ ok: boolean; message?: string }>;
  register: (payload: {
    username: string;
    password: string;
    role?: string;
  }) => Promise<{ ok: boolean; message?: string }>;
  logout: () => Promise<void>;
  isAuthenticated: boolean;
  roles: string[];
  userRole: string;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function parseRoles(raw: unknown): string[] {
  if (!raw) return [];
  if (Array.isArray(raw)) {
    return raw.map((role) => String(role).toUpperCase());
  }
  if (typeof raw === 'string') {
    return raw.split(',').map((role) => role.trim().toUpperCase());
  }
  return [];
}

function extractRoles(token: string): string[] {
  try {
    const decoded = jwtDecode<Record<string, unknown>>(token);
    return parseRoles(decoded.roles || decoded.authorities || decoded.role);
  } catch {
    return [];
  }
}

function readableName(value: unknown): string {
  const text = value == null ? "" : String(value).trim();
  if (!text || /^\?+$/.test(text)) return "";
  return text;
}

function loadStoredAuth(): AuthState | null {
  const token = localStorage.getItem('authToken');
  if (!token) return null;
  const roles = extractRoles(token).map((role) => role.replace('ROLE_', ''));
  return {
    token,
    roles,
    userRole: localStorage.getItem('userRole') || roles[0] || ROLES.USER,
    userName: localStorage.getItem('userName') || '',
    userEmail: localStorage.getItem('userEmail') || '',
    driverName: localStorage.getItem('driverName') || '',
    userId: localStorage.getItem('userId') || '',
    driverId: localStorage.getItem('driverId') || '',
  };
}

function persistProfileFields(values: {
  userRole: string;
  userName: string;
  userEmail: string;
  driverName?: string;
  userId?: string;
  driverId?: string;
}): void {
  localStorage.setItem('userRole', values.userRole);
  localStorage.setItem('userName', values.userName);
  localStorage.setItem('userEmail', values.userEmail);
  if (values.driverName) localStorage.setItem('driverName', values.driverName);
  else localStorage.removeItem('driverName');
  if (values.userId) localStorage.setItem('userId', values.userId);
  else localStorage.removeItem('userId');
  if (values.driverId) localStorage.setItem('driverId', values.driverId);
  else localStorage.removeItem('driverId');
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const navigate = useNavigate();
  const [auth, setAuth] = useState<AuthState | null>(() => loadStoredAuth());
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    setAuthCallbacks({
      onLogout: () => setAuth(null),
      onNavigate: (path) => navigate(path, { replace: true }),
    });
    setRefreshHook(refreshSession);
    return () => {
      setAuthCallbacks();
      setRefreshHook(null);
    };
  }, [navigate]);

  useEffect(() => {
    if (auth?.token) {
      setAuthToken(auth.token);
    } else {
      setAuthToken(null);
    }
  }, [auth?.token]);

  useEffect(() => {
    if (!auth?.token) return;
    let cancelled = false;
    getCurrentProfile()
      .then((profile) => {
        if (cancelled) return;
        setAuth((current) => {
          if (!current?.token) return current;
          const userId = profile.authUserId != null ? String(profile.authUserId) : current.userId;
          const driverId = profile.driverId != null ? String(profile.driverId) : '';
          const next = {
            ...current,
            userId,
            driverId,
            userName: readableName(profile.displayName) || profile.username || current.userName,
            userEmail: profile.email || current.userEmail,
            driverName: readableName(profile.driverName),
          };
          persistProfileFields({
            userRole: next.userRole,
            userName: next.userName,
            userEmail: next.userEmail,
            driverName: next.driverName,
            userId: next.userId,
            driverId: next.driverId,
          });
          return next;
        });
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [auth?.token]);

  const login = useCallback(async (username: string, password: string) => {
    setLoading(true);
    try {
      const result = await loginApi({ username, password });
      const token = result?.jwtToken || result?.accessToken;
      if (!token) {
        throw new Error(result?.message || result?.error || '登录失败');
      }
      const roles = extractRoles(token);
      const normalizedRoles = roles.map((role) => role.replace('ROLE_', ''));
      const userRole = (normalizedRoles[0] as RoleValue) || ROLES.USER;
      const user = result?.user;
      const refreshToken = result?.refreshToken;
      setTokens(token, typeof refreshToken === 'string' ? refreshToken : null);
      setAuthToken(token);

      let profile: Awaited<ReturnType<typeof getCurrentProfile>> | null = null;
      try {
        profile = await getCurrentProfile();
      } catch {
        profile = null;
      }

      const accountName = result?.username || profile?.username || username;
      const resolvedName =
        readableName(profile?.displayName) ||
        readableName(result?.displayName) ||
        readableName(user?.name) ||
        readableName(user?.realName) ||
        accountName.split('@')[0];
      const resolvedEmail = profile?.email || user?.email || (username.includes('@') ? username : '');
      const userId = String(profile?.authUserId ?? result?.authUserId ?? user?.userId ?? '');
      const driverIdValue = profile?.driverId ?? result?.driverId ?? user?.driverId;
      const driverId = driverIdValue != null && driverIdValue !== '' ? String(driverIdValue) : '';
      const driverName =
        readableName(profile?.driverName) || readableName(result?.driverName) || readableName(user?.driverName);

      persistProfileFields({
        userRole,
        userName: resolvedName,
        userEmail: resolvedEmail,
        driverName,
        userId,
        driverId,
      });

      setAuth({
        token,
        roles: normalizedRoles,
        userRole,
        userName: resolvedName,
        userEmail: resolvedEmail,
        driverName,
        userId,
        driverId,
      });
      return { ok: true };
    } catch (error) {
      const message =
        (error as { response?: { data?: { error?: string } }; message?: string })?.response?.data
          ?.error ||
        (error as { message?: string })?.message ||
        '登录失败';
      return { ok: false, message };
    } finally {
      setLoading(false);
    }
  }, []);

  const register = useCallback(
    async (payload: { username: string; password: string; role?: string }) => {
      setLoading(true);
      try {
        const result = await registerApi({
          username: payload.username,
          password: payload.password,
          role: payload.role || ROLES.USER,
          idempotencyKey: crypto?.randomUUID ? crypto.randomUUID() : undefined,
        });
        if (result?.status !== 'CREATED') {
          throw new Error(result?.error || '注册失败');
        }
        return { ok: true };
      } catch (error) {
        const message =
          (error as { response?: { data?: { error?: string } }; message?: string })?.response?.data
            ?.error ||
          (error as { message?: string })?.message ||
          '注册失败';
        return { ok: false, message };
      } finally {
        setLoading(false);
      }
    },
    []
  );

  const logout = useCallback(async () => {
    const refreshToken = getRefreshToken();
    await logoutRefresh(refreshToken); // 通知后端吊销 refresh token（失败不阻塞）
    clearStoredAuth();
    clearTokens();
    setAuth(null);
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      auth,
      loading,
      login,
      register,
      logout,
      isAuthenticated: Boolean(auth?.token),
      roles: auth?.roles || [],
      userRole: auth?.userRole || ROLES.USER,
    }),
    [auth, loading, login, register, logout]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return ctx;
}
