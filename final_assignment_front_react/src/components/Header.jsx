import React from 'react';
import { FiSun, FiMoon, FiUser } from 'react-icons/fi';
import { useAuth } from '../auth/AuthContext.jsx';
import { ROLES } from '../constants/roles.js';

/**
 * @component Header
 * @description 应用顶部头部栏，展示标题、主题切换按钮和当前用户信息。
 *
 * @param {{
 *   title: string,
 *   subtitle?: string,
 *   onToggleTheme: () => void,
 *   theme: string,
 * }} props - 页面标题、辅助标题、主题切换回调和当前主题标识。
 *
 * @notes
 * - 当前没有 actions/onBack prop；右侧区域固定为主题切换和用户信息。
 */
export default function Header({ title, subtitle, onToggleTheme, theme }) {
  const { auth } = useAuth();
  const userName = auth?.driverName || auth?.userName || '访客';
  const role = auth?.userRole || ROLES.USER;

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

