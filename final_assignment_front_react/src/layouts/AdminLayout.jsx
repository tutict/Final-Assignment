import React from 'react';
import AppShell from './AppShell.jsx';
import { adminNav } from '../config/adminNavigation.js';

export default function AdminLayout() {
  return (
    <AppShell
      navTitle="系统运维"
      navItems={adminNav}
      headerTitle="系统运维控制台"
      headerSubtitle="日志、配置与后台工具"
    />
  );
}
