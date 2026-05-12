import React from 'react';
import { NavLink } from 'react-router-dom';
import clsx from 'clsx';
import { useAuth } from '../auth/AuthContext.jsx';

/**
 * @component SidebarItem
 * @description 侧边导航单项，负责渲染图标、标签和路由链接。
 *
 * @param {{
 *   item: {
 *     label: string,
 *     path: string,
 *     icon?: React.ComponentType,
 *     isLogout?: boolean,
 *   },
 * }} props - 单个导航项配置。
 */
function SidebarItem({ item }) {
  const Icon = item.icon;
  return (
    <NavLink
      to={item.path}
      className={({ isActive }) =>
        clsx('sidebar-link', isActive && 'is-active', item.isLogout && 'is-logout')
      }
    >
      {Icon ? <Icon className="sidebar-icon" /> : null}
      <span>{item.label}</span>
    </NavLink>
  );
}

/**
 * @component Sidebar
 * @description 应用侧边导航栏，渲染主导航与快捷入口并支持退出登录项。
 *
 * @param {{
 *   title: string,
 *   items: Array<{ label: string, path: string, icon?: React.ComponentType, isLogout?: boolean }>,
 *   footerItems?: Array<{ label: string, path: string, icon?: React.ComponentType, isLogout?: boolean }>,
 * }} props - 导航分组标题、主导航和快捷入口。
 *
 * @notes
 * - 当前没有 collapsed/activePath prop；激活态由 NavLink 根据路由自动判断。
 * - 导航项结构使用 items/footerItems，不是 navItems。
 */
export default function Sidebar({ title, items, footerItems }) {
  const { logout } = useAuth();

  const handleClick = (item) => {
    if (item.isLogout) {
      logout();
    }
  };

  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <div className="brand-mark">TA</div>
        <div>
          <div className="brand-title">交通违法管理</div>
          <div className="brand-sub">Traffic Admin</div>
        </div>
      </div>
      <div className="sidebar-section">
        <div className="sidebar-section-title">{title}</div>
        <nav className="sidebar-nav">
          {items.map((item) => (
            <div key={item.path} onClick={() => handleClick(item)}>
              <SidebarItem item={item} />
            </div>
          ))}
        </nav>
      </div>
      {footerItems?.length ? (
        <div className="sidebar-section sidebar-footer">
          <div className="sidebar-section-title">快捷入口</div>
          <nav className="sidebar-nav">
            {footerItems.map((item) => (
              <div key={item.path} onClick={() => handleClick(item)}>
                <SidebarItem item={item} />
              </div>
            ))}
          </nav>
        </div>
      ) : null}
    </aside>
  );
}

