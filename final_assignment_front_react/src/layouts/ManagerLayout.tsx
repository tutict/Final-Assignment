import AppShell from './AppShell';
import { businessNav } from '../config/navigation';

export default function ManagerLayout() {
  return (
    <AppShell
      navTitle="管理模块"
      navItems={businessNav}
      headerTitle="交通违法处理管理系统"
      headerSubtitle="管理员工作台"
    />
  );
}
