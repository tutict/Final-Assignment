import { useEffect } from 'react';
import { Outlet } from 'react-router-dom';
import Sidebar from '../components/Sidebar';
import Header from '../components/Header';
import { useTheme } from '../theme/ThemeContext';
import type { NavItem } from '../config/navigation';

interface AppShellProps {
  navTitle: string;
  navItems: NavItem[];
  footerItems?: NavItem[];
  headerTitle: string;
  headerSubtitle?: string;
}

export default function AppShell({
  navTitle,
  navItems,
  footerItems,
  headerTitle,
  headerSubtitle,
}: AppShellProps) {
  const { theme, toggleTheme } = useTheme();

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
  }, [theme]);

  return (
    <div className="app-shell">
      <Sidebar title={navTitle} items={navItems} footerItems={footerItems} />
      <div className="app-main">
        <Header
          title={headerTitle}
          subtitle={headerSubtitle}
          onToggleTheme={toggleTheme}
          theme={theme}
        />
        <main className="app-content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
