import React, { useEffect, useState } from 'react';
import { Outlet } from 'react-router-dom';
import Sidebar from '../components/Sidebar.jsx';
import Header from '../components/Header.jsx';

const THEME_KEY = 'appTheme';

export default function AppShell({ navTitle, navItems, footerItems, headerTitle, headerSubtitle }) {
  const [theme, setTheme] = useState(() => localStorage.getItem(THEME_KEY) || 'light');

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem(THEME_KEY, theme);
  }, [theme]);

  return (
    <div className="app-shell">
      <Sidebar title={navTitle} items={navItems} footerItems={footerItems} />
      <div className="app-main">
        <Header
          title={headerTitle}
          subtitle={headerSubtitle}
          onToggleTheme={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
          theme={theme}
        />
        <main className="app-content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

