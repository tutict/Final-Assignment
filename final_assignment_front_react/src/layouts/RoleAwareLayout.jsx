import React from 'react';
import AppShell from './AppShell.jsx';
import { managerNav, userNav, utilityNav } from '../config/navigation.js';
import { useAuth } from '../auth/AuthContext.jsx';

export default function RoleAwareLayout({ headerTitle, headerSubtitle }) {
  const { userRole } = useAuth();
  const isAdmin = ['ADMIN', 'SUPER_ADMIN', 'APPEAL_REVIEWER'].includes(userRole);
  return (
    <AppShell
      navTitle={isAdmin ? '管理模块' : '用户中心'}
      navItems={isAdmin ? managerNav : userNav}
      footerItems={utilityNav}
      headerTitle={headerTitle}
      headerSubtitle={headerSubtitle}
    />
  );
}
