import { FiSun, FiMoon, FiUser, FiMessageCircle } from 'react-icons/fi';
import clsx from 'clsx';
import { useLocation } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { ROLES, resolveRoleLabel } from '../constants/roles';
import { useAgentWindow } from '../layouts/AgentWindowContext';

interface HeaderProps {
  title: string;
  subtitle?: string;
  onToggleTheme: () => void;
  theme: string;
}

export default function Header({ title, subtitle, onToggleTheme, theme }: HeaderProps) {
  const { auth } = useAuth();
  const { open, toggle } = useAgentWindow();
  const location = useLocation();
  const userName = auth?.driverName || auth?.userName || '访客';
  const role = auth?.userRole || ROLES.USER;
  const isChatPage = location.pathname.endsWith('/aiChat');
  const chatActive = open || isChatPage;

  return (
    <header className="app-header">
      <div>
        <div className="header-title">{title}</div>
        {subtitle ? <div className="header-subtitle">{subtitle}</div> : null}
      </div>
      <div className="header-actions">
        <button
          className={clsx('icon-button', chatActive && 'is-active')}
          onClick={toggle}
          type="button"
          aria-pressed={chatActive}
          aria-label="AI 助手"
          title="AI 助手"
          disabled={isChatPage}
        >
          <FiMessageCircle />
        </button>
        <button className="icon-button" onClick={onToggleTheme} type="button" aria-label="切换明暗主题" title="切换明暗主题">
          {theme === 'dark' ? <FiSun /> : <FiMoon />}
        </button>
        <div className="header-user">
          <FiUser />
          <span>{userName}</span>
          <span className="header-role">{resolveRoleLabel(role)}</span>
        </div>
      </div>
    </header>
  );
}
