import {
  FiHome,
  FiUsers,
  FiShield,
  FiAlertTriangle,
  FiTruck,
  FiCreditCard,
  FiFileText,
  FiActivity,
  FiClipboard,
  FiLayers,
  FiBookOpen,
  FiTool,
  FiLogOut,
} from 'react-icons/fi';

export const businessNav = [
  { label: '管理仪表盘', path: '/dashboard', icon: FiHome },
  { label: '交通违法概览', path: '/trafficViolationScreen', icon: FiActivity },
  { label: '违法记录', path: '/offenseList', icon: FiAlertTriangle },
  { label: '违法类型', path: '/offenseType', icon: FiShield },
  { label: '扣分记录', path: '/deductionManagement', icon: FiClipboard },
  { label: '罚款记录', path: '/fineList', icon: FiCreditCard },
  { label: '缴费记录', path: '/paymentRecord', icon: FiCreditCard },
  { label: '申诉管理', path: '/appealManagement', icon: FiFileText },
  { label: '驾驶员管理', path: '/driverList', icon: FiUsers },
  { label: '车辆管理', path: '/vehicleList', icon: FiTruck },
  { label: '业务进度', path: '/progressManagement', icon: FiLayers },
];

export const managerNav = businessNav;

export const userNav = [
  { label: '用户仪表盘', path: '/userDashboard', icon: FiHome },
  { label: '违法记录', path: '/userOffenseListPage', icon: FiAlertTriangle },
  { label: '车辆管理', path: '/vehicleManagement', icon: FiTruck },
  { label: '罚款信息', path: '/fineInformation', icon: FiCreditCard },
  { label: '业务进度', path: '/businessProgress', icon: FiLayers },
  { label: '在线办理进度', path: '/onlineProcessingProgress', icon: FiClipboard },
  { label: '我的申诉', path: '/userAppeal', icon: FiFileText },
];

export const utilityNav = [
  { label: '事故快处指南', path: '/accidentQuickGuidePage', icon: FiBookOpen },
  { label: '事故处理流程', path: '/accidentProgressPage', icon: FiBookOpen },
  { label: '事故证据采集', path: '/accidentEvidencePage', icon: FiBookOpen },
  { label: '事故视频教程', path: '/accidentVideoQuickPage', icon: FiBookOpen },
  { label: '罚款缴纳说明', path: '/finePaymentNoticePage', icon: FiBookOpen },
  { label: '扫一扫', path: '/mainScan', icon: FiTool },
  { label: '安全退出', path: '/login', icon: FiLogOut, isLogout: true },
];
