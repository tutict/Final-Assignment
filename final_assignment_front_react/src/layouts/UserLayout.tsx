import AppShell from './AppShell';
import { userNav } from '../config/navigation';

export default function UserLayout() {
  return (
    <AppShell
      navTitle="用户中心"
      navItems={userNav}
      headerTitle="交通违法处理服务平台"
      headerSubtitle="用户服务中心"
    />
  );
}
