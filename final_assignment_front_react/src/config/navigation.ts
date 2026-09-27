import type { IconType } from 'react-icons';
import {
  FiHome,
  FiAlertTriangle,
  FiTruck,
  FiCreditCard,
  FiFileText,
  FiClipboard,
  FiMap,
  FiUser,
  FiSettings,
  FiMessageSquare,
  FiUsers,
  FiDatabase,
  FiShield,
  FiActivity,
  FiTool,
  FiSearch,
  FiBookOpen,
} from 'react-icons/fi';
import { ROLES, type RoleCode } from '../constants/roles';

export interface NavItem {
  label: string;
  path: string;
  icon?: IconType;
  roles: RoleCode[];
}

export interface NavGroup {
  id: string;
  label: string;
  defaultCollapsed?: boolean;
  items: NavItem[];
}

const USER: RoleCode[] = [ROLES.USER];
const STAFF: RoleCode[] = [ROLES.ADMIN, ROLES.SUPER_ADMIN];
const APPEAL: RoleCode[] = [ROLES.APPEAL_REVIEWER];
const STAFF_AND_APPEAL: RoleCode[] = [ROLES.ADMIN, ROLES.SUPER_ADMIN, ROLES.APPEAL_REVIEWER];
const SUPER: RoleCode[] = [ROLES.SUPER_ADMIN];
const MAP_ROLES: RoleCode[] = [ROLES.USER];

export const shellNav: NavGroup[] = [
  {
    id: 'home',
    label: '首页',
    items: [
      { label: '首页', path: '/userDashboard', icon: FiHome, roles: USER },
      { label: '首页', path: '/dashboard', icon: FiHome, roles: STAFF_AND_APPEAL },
    ],
  },
  {
    id: 'tasks',
    label: '办事',
    items: [
      { label: '我的违法', path: '/userOffenseListPage', icon: FiAlertTriangle, roles: USER },
      { label: '缴费', path: '/fineInformation', icon: FiCreditCard, roles: USER },
      { label: '申诉', path: '/userAppeal', icon: FiFileText, roles: USER },
      { label: '我的车辆', path: '/vehicleManagement', icon: FiTruck, roles: USER },
    ],
  },
  {
    id: 'business',
    label: '业务',
    items: [
      { label: '违法行为', path: '/offenseList', icon: FiAlertTriangle, roles: STAFF },
      { label: '罚款', path: '/fineList', icon: FiCreditCard, roles: STAFF },
      { label: '扣分', path: '/deductionManagement', icon: FiClipboard, roles: STAFF },
      { label: '申诉', path: '/appealManagement', icon: FiFileText, roles: [...STAFF, ...APPEAL] },
      { label: '驾驶员', path: '/driverList', icon: FiUsers, roles: STAFF },
      { label: '车辆', path: '/vehicleList', icon: FiTruck, roles: STAFF },
    ],
  },
  {
    id: 'lookup',
    label: '查询',
    items: [
      { label: '消息', path: '/onlineProcessingProgress', icon: FiMessageSquare, roles: USER },
      { label: '地图', path: '/admin/map', icon: FiMap, roles: MAP_ROLES },
    ],
  },
  {
    id: 'oversight',
    label: '监管',
    items: [
      { label: '消息', path: '/progressManagement', icon: FiMessageSquare, roles: STAFF_AND_APPEAL },
      { label: '缴费流水', path: '/paymentRecord', icon: FiCreditCard, roles: STAFF },
    ],
  },
  {
    id: 'library',
    label: '资料',
    items: [{ label: 'RAG 资料', path: '/ragManagement', icon: FiDatabase, roles: STAFF }],
  },
  {
    id: 'system',
    label: '系统',
    defaultCollapsed: true,
    items: [
      { label: '操作日志', path: '/admin/operationLogPage', icon: FiClipboard, roles: SUPER },
      { label: '登录日志', path: '/admin/loginLogPage', icon: FiActivity, roles: SUPER },
      { label: '系统日志', path: '/admin/systemLogPage', icon: FiActivity, roles: SUPER },
      { label: '请求记录', path: '/admin/requestHistory', icon: FiSearch, roles: SUPER },
      { label: '账号', path: '/admin/userManagementPage', icon: FiUsers, roles: SUPER },
      { label: '角色', path: '/admin/roleManagement', icon: FiShield, roles: SUPER },
      { label: '权限', path: '/admin/permissionManagement', icon: FiShield, roles: SUPER },
      { label: '违法类型', path: '/offenseType', icon: FiBookOpen, roles: SUPER },
      { label: '系统参数', path: '/admin/systemSettings', icon: FiSettings, roles: SUPER },
      { label: '备份恢复', path: '/admin/backupAndRestore', icon: FiTool, roles: SUPER },
    ],
  },
  {
    id: 'account',
    label: '我的',
    items: [
      { label: '个人资料', path: '/personalMain', icon: FiUser, roles: USER },
      { label: '咨询反馈', path: '/consultation', icon: FiMessageSquare, roles: USER },
      { label: '设置', path: '/userSetting', icon: FiSettings, roles: USER },
      { label: '个人资料', path: '/admin/managerPersonalPage', icon: FiUser, roles: STAFF_AND_APPEAL },
      { label: '设置', path: '/admin/managerSetting', icon: FiSettings, roles: STAFF_AND_APPEAL },
    ],
  },
];

export function normalizeRole(role: string | null | undefined): string {
  return (role || ROLES.USER).replace(/^ROLE_/, '');
}

export function navForRole(role: string | null | undefined): NavGroup[] {
  const current = normalizeRole(role);
  return shellNav
    .map((group) => ({
      ...group,
      items: group.items.filter((item) => item.roles.includes(current as RoleCode)),
    }))
    .filter((group) => group.items.length > 0);
}

export function flatNavForRole(role: string | null | undefined): NavItem[] {
  return navForRole(role).flatMap((group) => group.items);
}

export function homePathForRole(role: string | null | undefined): string {
  const current = normalizeRole(role);
  if (current === ROLES.ADMIN || current === ROLES.SUPER_ADMIN || current === ROLES.APPEAL_REVIEWER) {
    return '/dashboard';
  }
  return '/userDashboard';
}

export function workspacePathForRole(role: string | null | undefined, saved: string | null | undefined): string {
  const home = homePathForRole(role);
  if (!saved) return home;
  const path = saved.split('?')[0];
  if (!path || path === '/' || path === '/login' || path === '/admin/aiChat') return home;
  const current = normalizeRole(role);
  const allowed = flatNavForRole(role).some((item) => path === item.path || path.startsWith(`${item.path}/`));
  const progressDetail = path.startsWith('/progressDetailPage');
  const scan = path.startsWith('/mainScan') && (current === ROLES.USER || current === ROLES.ADMIN || current === ROLES.SUPER_ADMIN);
  return allowed || progressDetail || scan ? saved : home;
}

export function messagePathForRole(role: string | null | undefined): string {
  return normalizeRole(role) === ROLES.USER ? '/onlineProcessingProgress' : '/progressManagement';
}

export function settingsPathForRole(role: string | null | undefined): string {
  return normalizeRole(role) === ROLES.USER ? '/userSetting' : '/admin/managerSetting';
}

export function profilePathForRole(role: string | null | undefined): string {
  return normalizeRole(role) === ROLES.USER ? '/personalMain' : '/admin/managerPersonalPage';
}

export function titleForPath(pathname: string, role: string | null | undefined): string {
  const match = flatNavForRole(role).find((item) => pathname === item.path || pathname.startsWith(`${item.path}/`));
  if (match) return match.label;
  if (pathname.startsWith('/progressDetailPage')) return '进度详情';
  if (pathname.startsWith('/mainScan')) return '缴费码';
  if (pathname.startsWith('/admin/aiChat')) return 'AI 助手';
  return '交通违法处理';
}

/** @deprecated 旧布局仍引用，壳层改为按角色计算。 */
export const businessNav = shellNav[2].items;
export const managerNav = businessNav;
export const userNav = shellNav[1].items;
export const utilityNav: NavItem[] = [];
