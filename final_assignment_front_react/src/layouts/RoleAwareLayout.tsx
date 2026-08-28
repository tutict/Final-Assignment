import AppShell from './AppShell';
import { businessNav, userNav } from '../config/navigation';
import { useAuth } from '../auth/AuthContext';
import { ROLES } from '../constants/roles';

interface RoleAwareLayoutProps {
  headerTitle: string;
  headerSubtitle?: string;
}

export default function RoleAwareLayout({ headerTitle, headerSubtitle }: RoleAwareLayoutProps) {
  const { userRole } = useAuth();
  const adminRoles: string[] = [ROLES.ADMIN, ROLES.SUPER_ADMIN, ROLES.APPEAL_REVIEWER];
  const isAdmin = adminRoles.includes(userRole);
  return (
    <AppShell
      navTitle={isAdmin ? '管理模块' : '用户中心'}
      navItems={isAdmin ? businessNav : userNav}
      headerTitle={headerTitle}
      headerSubtitle={headerSubtitle}
    />
  );
}
