/**
 * 管理员业务处理中心，对齐 Flutter ManagerBusinessProcessing。
 * 6 个入口瓦片：申诉管理 / 扣分管理 / 司机管理 / 罚款管理 / 车辆管理 / 违法行为。
 */
import {
  FiCheckSquare,
  FiCreditCard,
  FiFlag,
  FiAlertCircle,
  FiTruck,
  FiUser,
} from 'react-icons/fi';
import BusinessHubPage from '../../components/BusinessHubPage';

const OPTIONS = [
  {
    title: '申诉管理',
    description: '复核驾驶员申诉材料、处理意见和办理进度',
    badge: '7 项待核',
    icon: FiFlag,
    target: '/appealManagement',
    accent: '#0c7c79',
  },
  {
    title: '扣分管理',
    description: '核对违法扣分记录，维护驾驶证计分状态',
    badge: '规则校验',
    icon: FiCheckSquare,
    target: '/deductionManagement',
    accent: '#25A7A0',
  },
  {
    title: '司机管理',
    description: '查看驾驶员档案、证件信息与账号关联状态',
    badge: '身份档案',
    icon: FiUser,
    target: '/driverList',
    accent: '#7C8CF8',
  },
  {
    title: '罚款管理',
    description: '跟进罚款开具、缴纳状态和异常款项处理',
    badge: '支付跟进',
    icon: FiCreditCard,
    target: '/fineList',
    accent: '#E65E73',
  },
  {
    title: '车辆管理',
    description: '维护车辆信息、绑定关系与违法关联记录',
    badge: '车辆台账',
    icon: FiTruck,
    target: '/vehicleList',
    accent: '#2F9B6A',
  },
  {
    title: '违法行为',
    description: '检索违法行为明细，快速定位待处理案件',
    badge: '数据核验',
    icon: FiAlertCircle,
    target: '/offenseList',
    accent: '#E5A33A',
  },
];

export default function ManagerBusinessProcessingPage() {
  return (
    <BusinessHubPage
      title="业务处理"
      subtitle="集中处理申诉、扣分、司机、罚款、车辆和违法行为数据"
      headerIcon={FiCheckSquare}
      headerNote="集中处理申诉、扣分、司机、罚款、车辆和违法行为数据。"
      options={OPTIONS}
      countLabel="6 个入口"
    />
  );
}
