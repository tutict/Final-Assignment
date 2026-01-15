import React from 'react';
import AppShell from './AppShell.jsx';
import { userNav, utilityNav } from '../config/navigation.js';

export default function UserLayout() {
  return (
    <AppShell
      navTitle="用户中心"
      navItems={userNav}
      footerItems={utilityNav}
      headerTitle="交通违法处理服务平台"
      headerSubtitle="用户服务中心"
    />
  );
}

