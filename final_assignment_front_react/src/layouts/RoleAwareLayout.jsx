import React from 'react';
import AppShell from './AppShell.jsx';
import { businessNav, userNav } from '../config/navigation.js';
import { useAuth } from '../auth/AuthContext.jsx';
import { ROLES } from '../constants/roles.js';

export default function RoleAwareLayout({ headerTitle, headerSubtitle }) {
  const { userRole } = useAuth();
  const isAdmin = [ROLES.ADMIN, ROLES.SUPER_ADMIN, ROLES.APPEAL_REVIEWER].includes(userRole);
  return (
    <AppShell
      navTitle={isAdmin ? '管理模块' : '用户中心'}
      navItems={isAdmin ? businessNav : userNav}
      headerTitle={headerTitle}
      headerSubtitle={headerSubtitle}
    />
  );
}
