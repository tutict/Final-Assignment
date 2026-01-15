import React from 'react';
import { NavLink } from 'react-router-dom';
import clsx from 'clsx';
import { useAuth } from '../auth/AuthContext.jsx';

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

