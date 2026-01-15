import React from 'react';
import AppShell from './AppShell.jsx';
import { managerNav, utilityNav } from '../config/navigation.js';

export default function ManagerLayout() {
  return (
    <AppShell
      navTitle="管理模块"
      navItems={managerNav}
      footerItems={utilityNav}
      headerTitle="交通违法处理管理系统"
      headerSubtitle="管理员工作台"
    />
  );
}

