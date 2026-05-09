import {
  FiBookOpen,
  FiClipboard,
  FiMap,
  FiMessageCircle,
  FiSettings,
  FiShield,
  FiTool,
  FiUsers,
} from 'react-icons/fi';

export const adminNav = [
  { label: '用户管理', path: '/admin/userManagementPage', icon: FiUsers },
  { label: '权限管理', path: '/admin/permissionManagement', icon: FiShield },
  { label: '角色管理', path: '/admin/roleManagement', icon: FiShield },
  { label: '日志管理', path: '/admin/logManagement', icon: FiClipboard },
  { label: '系统设置', path: '/admin/systemSettings', icon: FiSettings },
  { label: '备份与恢复', path: '/admin/backupAndRestore', icon: FiTool },
  { label: 'AI 助手', path: '/admin/aiChat', icon: FiMessageCircle },
  { label: '数据地图', path: '/admin/map', icon: FiMap },
  { label: '管理员信息', path: '/admin/managerPersonalPage', icon: FiBookOpen },
  { label: '管理员设置', path: '/admin/managerSetting', icon: FiSettings },
];
