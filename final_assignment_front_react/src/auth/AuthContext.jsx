import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { jwtDecode } from 'jwt-decode';
import { login as loginApi, register as registerApi } from '../api/auth';
import { setAuthToken } from '../api/client';

const AuthContext = createContext(null);

function parseRoles(raw) {
  if (!raw) return [];
  if (Array.isArray(raw)) {
    return raw.map((role) => String(role).toUpperCase());
  }
  if (typeof raw === 'string') {
    return raw.split(',').map((role) => role.trim().toUpperCase());
  }
  return [];
}

function extractRoles(token) {
  try {
    const decoded = jwtDecode(token);
    return parseRoles(decoded.roles || decoded.authorities || decoded.role);
  } catch (error) {
    return [];
  }
}

function loadStoredAuth() {
  const token = localStorage.getItem('authToken');
  if (!token) return null;
  const roles = extractRoles(token).map((role) => role.replace('ROLE_', ''));
  return {
    token,
    roles,
    userRole: localStorage.getItem('userRole') || roles[0] || 'USER',
    userName: localStorage.getItem('userName') || '',
    userEmail: localStorage.getItem('userEmail') || '',
    driverName: localStorage.getItem('driverName') || '',
    userId: localStorage.getItem('userId') || '',
  };
}

export function AuthProvider({ children }) {
  const [auth, setAuth] = useState(() => loadStoredAuth());
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (auth?.token) {
      setAuthToken(auth.token);
    } else {
      setAuthToken(null);
    }
  }, [auth?.token]);

  const login = useCallback(async (username, password) => {
    setLoading(true);
    try {
      const result = await loginApi({ username, password });
      const token = result?.jwtToken;
      if (!token) {
        throw new Error(result?.message || result?.error || '登录失败');
      }
      const roles = extractRoles(token);
      const normalizedRoles = roles.map((role) => role.replace('ROLE_', ''));
      const userRole = normalizedRoles[0] || 'USER';
      const user = result?.user || {};
      const resolvedName = user?.name || user?.realName || username.split('@')[0];
      const resolvedEmail = user?.email || username;
      const userId = user?.userId ? String(user.userId) : '';
      const driverName = user?.driverName || resolvedName;

      localStorage.setItem('authToken', token);
      localStorage.setItem('userRole', userRole);
      localStorage.setItem('userName', resolvedName);
      localStorage.setItem('userEmail', resolvedEmail);
      if (driverName) localStorage.setItem('driverName', driverName);
      if (userId) localStorage.setItem('userId', userId);

      setAuth({
        token,
        roles: normalizedRoles,
        userRole,
        userName: resolvedName,
        userEmail: resolvedEmail,
        driverName,
        userId,
      });
      return { ok: true };
    } catch (error) {
      const message = error?.response?.data?.error || error?.message || '登录失败';
      return { ok: false, message };
    } finally {
      setLoading(false);
    }
  }, []);

  const register = useCallback(async ({ username, password, role }) => {
    setLoading(true);
    try {
      const result = await registerApi({
        username,
        password,
        role: role || 'USER',
        idempotencyKey: crypto?.randomUUID ? crypto.randomUUID() : undefined,
      });
      if (result?.status !== 'CREATED') {
        throw new Error(result?.error || '注册失败');
      }
      return { ok: true };
    } catch (error) {
      const message = error?.response?.data?.error || error?.message || '注册失败';
      return { ok: false, message };
    } finally {
      setLoading(false);
    }
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem('authToken');
    localStorage.removeItem('userRole');
    localStorage.removeItem('userName');
    localStorage.removeItem('userEmail');
    localStorage.removeItem('driverName');
    localStorage.removeItem('userId');
    setAuth(null);
  }, []);

  const value = useMemo(
    () => ({
      auth,
      loading,
      login,
      register,
      logout,
      isAuthenticated: Boolean(auth?.token),
      roles: auth?.roles || [],
      userRole: auth?.userRole || 'USER',
    }),
    [auth, loading, login, register, logout]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return ctx;
}

