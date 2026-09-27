import { useEffect, useState } from 'react';
import { NavLink } from 'react-router-dom';
import clsx from 'clsx';
import { useAuth } from '../auth/AuthContext';
import { navForRole, normalizeRole } from '../config/navigation';
import { ROLES } from '../constants/roles';

interface SidebarProps {
  collapsed: boolean;
  mobile: boolean;
  onNavigate?: () => void;
}

export default function Sidebar({ collapsed, mobile, onNavigate }: SidebarProps) {
  const { userRole } = useAuth();
  const groups = navForRole(userRole);
  const staff = [ROLES.ADMIN, ROLES.SUPER_ADMIN, ROLES.APPEAL_REVIEWER].includes(
    normalizeRole(userRole) as typeof ROLES.ADMIN
  );
  const [collapsedGroups, setCollapsedGroups] = useState<Record<string, boolean>>(() =>
    Object.fromEntries(groups.map((group) => [group.id, Boolean(group.defaultCollapsed)]))
  );

  useEffect(() => {
    setCollapsedGroups((prev) => {
      const next = { ...prev };
      groups.forEach((group) => {
        if (!(group.id in next)) next[group.id] = Boolean(group.defaultCollapsed);
      });
      return next;
    });
  }, [userRole]);

  return (
    <aside className="sidebar" aria-label="主导航">
      <div className="sidebar-brand">
        <div className="brand-mark">{staff ? '管' : '办'}</div>
        {collapsed && !mobile ? null : (
          <div>
            <div className="brand-title">{staff ? '交通违法管理' : '交通违法办事'}</div>
            <div className="brand-sub">{staff ? '管理后台' : '个人中心'}</div>
          </div>
        )}
      </div>
      <nav className="sidebar-nav">
        {groups.map((group) => {
          const hidden = collapsedGroups[group.id] && !(collapsed && !mobile);
          return (
            <div key={group.id}>
              {collapsed && !mobile ? null : (
                <button
                  type="button"
                  className="nav-group-label"
                  aria-expanded={!hidden}
                  onClick={() =>
                    setCollapsedGroups((prev) => ({ ...prev, [group.id]: !prev[group.id] }))
                  }
                >
                  <span>{group.label}</span>
                  <span>{hidden ? '展开' : '收起'}</span>
                </button>
              )}
              {hidden ? null : (
                <div className="sidebar-nav">
                  {group.items.map((item) => {
                    const Icon = item.icon;
                    const link = (
                      <NavLink
                        to={item.path}
                        title={collapsed ? item.label : undefined}
                        onClick={onNavigate}
                        className={({ isActive }) => clsx('sidebar-link', isActive && 'is-active')}
                      >
                        {Icon ? <Icon className="sidebar-icon" aria-hidden /> : null}
                        {collapsed && !mobile ? <span className="sr-only">{item.label}</span> : <span>{item.label}</span>}
                      </NavLink>
                    );
                    return collapsed && !mobile ? (
                      <div key={item.path} title={item.label}>
                        {link}
                      </div>
                    ) : (
                      <div key={item.path}>{link}</div>
                    );
                  })}
                </div>
              )}
            </div>
          );
        })}
      </nav>
    </aside>
  );
}
