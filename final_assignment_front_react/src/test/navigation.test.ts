import { describe, expect, it } from 'vitest';
import { homePathForRole, normalizeRole, titleForPath, workspacePathForRole } from '../config/navigation';

describe('role-based navigation', () => {
  it('normalizes Spring Security role prefixes', () => {
    expect(normalizeRole('ROLE_ADMIN')).toBe('ADMIN');
    expect(normalizeRole('USER')).toBe('USER');
    expect(normalizeRole(null)).toBe('USER');
    expect(normalizeRole(undefined)).toBe('USER');
  });

  it('routes staff and appeal reviewers to the admin dashboard, drivers to theirs', () => {
    expect(homePathForRole('ROLE_ADMIN')).toBe('/dashboard');
    expect(homePathForRole('ROLE_SUPER_ADMIN')).toBe('/dashboard');
    expect(homePathForRole('ROLE_APPEAL_REVIEWER')).toBe('/dashboard');
    expect(homePathForRole('ROLE_USER')).toBe('/userDashboard');
    expect(homePathForRole(null)).toBe('/userDashboard');
  });

  it('falls back to the role home path for login/aiChat workspaces', () => {
    expect(workspacePathForRole('ROLE_USER', '/login?from=x')).toBe('/userDashboard');
    expect(workspacePathForRole('ROLE_ADMIN', '/admin/aiChat')).toBe('/dashboard');
    expect(workspacePathForRole('ROLE_ADMIN', '/driverList')).toBe('/driverList');
    expect(workspacePathForRole('ROLE_ADMIN', undefined)).toBe('/dashboard');
  });

  it('resolves page titles from the nav tree and special paths', () => {
    expect(titleForPath('/fineList', 'ROLE_ADMIN')).toBe('罚款');
    expect(titleForPath('/admin/aiChat', 'ROLE_ADMIN')).toBe('AI 助手');
    expect(titleForPath('/progressDetailPage/1', 'ROLE_USER')).toBe('进度详情');
    expect(titleForPath('/unknown', 'ROLE_USER')).toBe('交通违法处理');
  });
});
