import { useQuery } from '@tanstack/react-query';
import { FiSun, FiMoon, FiUser, FiMessageCircle, FiMenu, FiBell } from 'react-icons/fi';
import { listProgress } from '../api/progress';
import { Link, useLocation } from 'react-router-dom';
import clsx from 'clsx';
import { useAuth } from '../auth/AuthContext';
import { clearStoredAuth } from '../api/client';
import { ROLES, resolveRoleLabel } from '../constants/roles';
import { messagePathForRole, profilePathForRole, settingsPathForRole, titleForPath } from '../config/navigation';
import { useAgentWindow } from '../layouts/AgentWindowContext';
import { useTheme } from '../theme/ThemeContext';

interface HeaderProps {
  onOpenNav?: () => void;
  showMenu?: boolean;
}

export default function Header({ onOpenNav, showMenu }: HeaderProps) {
  const { auth, logout, userRole } = useAuth();
  const { open, openAgent, close } = useAgentWindow();
  const { theme, toggleTheme } = useTheme();
  const location = useLocation();
  const userName = auth?.driverName || auth?.userName || '访客';
  const role = auth?.userRole || userRole || ROLES.USER;
  const title = titleForPath(location.pathname, role);
  const unread = useQuery({
    queryKey: ['progress', 'unread-count'],
    queryFn: listProgress,
    retry: false,
  });
  const unreadCount = unread.data?.length ?? 0;

  const toggleChat = () => {
    if (open) close();
    else openAgent();
  };

  return (
    <header className="app-header">
      <div>
        <div className="header-title">{title}</div>
        <div className="header-subtitle">交通违法处理</div>
      </div>
      <div className="header-actions">
        {showMenu ? (
          <button className="icon-button" type="button" aria-label="打开导航" onClick={onOpenNav}>
            <FiMenu />
          </button>
        ) : null}
        <Link className="icon-button unread-link" to={messagePathForRole(role)} aria-label={unreadCount > 0 ? `未读消息 ${unreadCount}` : '未读消息'} title="消息">
          <FiBell />
          {unreadCount > 0 ? <span className="unread-count">{unreadCount > 99 ? '99+' : unreadCount}</span> : null}
        </Link>
        <button
          className={clsx('icon-button', open && 'is-active')}
          onClick={toggleChat}
          type="button"
          aria-pressed={open}
          aria-label="AI 助手"
          title="AI 助手"
        >
          <FiMessageCircle />
        </button>
        <button className="icon-button" onClick={toggleTheme} type="button" aria-label="切换明暗" title="切换明暗">
          {theme === 'dark' ? <FiSun /> : <FiMoon />}
        </button>
        <details className="account-menu">
          <summary className="header-user" aria-label="账号菜单">
            <FiUser />
            <span>{userName}</span>
            <span className="header-role">{resolveRoleLabel(role)}</span>
          </summary>
          <div className="account-menu-panel">
            <Link to={profilePathForRole(role)}>个人资料</Link>
            <Link to={settingsPathForRole(role)}>设置</Link>
            <button
              type="button"
              onClick={() => {
                void logout().finally(() => clearStoredAuth());
              }}
            >
              退出登录
            </button>
          </div>
        </details>
      </div>
    </header>
  );
}
