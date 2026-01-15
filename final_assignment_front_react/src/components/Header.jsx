import React from 'react';
import { FiSun, FiMoon, FiUser } from 'react-icons/fi';
import { useAuth } from '../auth/AuthContext.jsx';

export default function Header({ title, subtitle, onToggleTheme, theme }) {
  const { auth } = useAuth();
  const userName = auth?.driverName || auth?.userName || '访客';
  const role = auth?.userRole || 'USER';

  return (
    <header className="app-header">
      <div>
        <div className="header-title">{title}</div>
        {subtitle ? <div className="header-subtitle">{subtitle}</div> : null}
      </div>
      <div className="header-actions">
        <button className="icon-button" onClick={onToggleTheme} type="button">
          {theme === 'dark' ? <FiSun /> : <FiMoon />}
        </button>
        <div className="header-user">
          <FiUser />
          <span>{userName}</span>
          <span className="header-role">{role}</span>
        </div>
      </div>
    </header>
  );
}

